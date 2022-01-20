export SteepestSolver
export finished, solve!, sample_two_shifts
export record_bestsol, get_stats
export liste_echanges_2_a_2, liste_blocs_permutation
using Random
"""
SteepestSolver

Résoud le problème global par statégie de descente profonde.

"""
mutable struct SteepestSolver
    inst::Instance
    nb_test::Int          # Nombre total de voisins testé
    nb_move::Int          # nombre de voisins acceptés 

    duration::Float64     # durée réelle (mesurée) de l'exécution
    durationmax::Float64  # durée max de l'exécution (--duration)
    starttime::Float64    # heure de début d'une résolution

    cursol::Solution      # Solution courante
    bestsol::Solution     # meilleure Solution rencontrée
    testsol::Solution     # nouvelle solution potentielle

    bestiter::Int
    do_save_bestsol::Bool
    blocked::Bool         # indique si le voisinage testé n'est pas améliorant
                          # si vrai on doit s'arrêter
    SteepestSolver() = new() # Constructeur par défaut
end

function SteepestSolver(inst::Instance; startsol::Union{Nothing,Solution} = nothing)
    ln3("Début constructeur de SteepestSolver")

    this = SteepestSolver()
    this.inst = inst
    this.nb_test = 0
    this.nb_move = 0

    this.durationmax = 366 * 24 * 3600 # 1 année par défaut !
    this.duration = 0.0 # juste pour initialisation
    this.starttime = 0.0 # juste pour initialisation
    if startsol == nothing
        # Pas de solution initiale => on en crée une
        this.cursol = Solution(inst)
        if Args.get(:presort) == :none
            # initial_sort!(this.cursol, presort=:shuffle) # proto
            initial_sort!(this.cursol, presort = :target) # diam
        else
            initial_sort!(this.cursol, presort = Args.get(:presort))
        end
    else
        this.cursol = startsol
        if lg2()
            println("Dans SteepestSolver : this.cursol = this.opts[:startsol] ")
            println("this.cursol", to_s(this.cursol))
        end
    end
    this.bestsol = Solution(this.cursol)
    this.testsol = Solution(this.cursol)
    this.blocked = false
    this.do_save_bestsol = false
    return this
end

# Retourne true ssi l'état justifie l'arrêt de l'algorithme
#
function finished(sv::SteepestSolver)
    sv.duration = time_ns() / 1_000_000_000 - sv.starttime
    too_long = sv.duration >= sv.durationmax
    other = sv.blocked
    stop = too_long || other
    if stop
        if lg1()
            println("\nSTOP car :")
            println("     sv.duration=$(sv.duration)")
            println("     sv.durationmax=$(sv.durationmax)")
            println("     sv.blocked=$(sv.blocked)")
            println(get_stats(sv))
        end
        return true
    else
        return false
    end
end

function solve!(
    sv::SteepestSolver;
    startsol::Union{Nothing,Solution} = nothing,
    durationmax::Int = 100,
)

    ln2("BEGIN solve!(SteepestSolver)")
    if durationmax != 0
        sv.durationmax = durationmax
    end
    if startsol != nothing
        sv.cursol = startsol
        copy!(sv.bestsol, sv.cursol) # on réinitialise bestsol à cursol
        copy!(sv.testsol, sv.cursol)
        if lg2()
            println("Dans SteepestSolver : sv.cursol = sv.opts[:startsol] ")
            println("sv.cursol : ", to_s(sv.cursol))
        end
    else
        # on garde la dernière solution sv.cursol
    end
    sv.starttime = time_ns() / 1_000_000_000
    
    # First best move 
    mode = Args.get("move_to_first_best")
    if mode==:false
        first_best = false
    else
        first_best = true
    end

    # Choix du voisinage
    vois = string(Args.get("nbh"))
    
    n = sv.inst.nb_planes
    voisinage = Voisinage([Mutation(0,Int64[],Int64[])])
    if occursin("s1",vois)
        voisinage = merge(voisinage,swap_vois(n,1))
    end
    if occursin("s2",vois)
        voisinage = merge(voisinage,swap_vois(n,2))
    end
    if occursin("s3",vois)
        voisinage = merge(voisinage,swap_vois(n,3))
    end
    if occursin("t2",vois)
        voisinage = merge(voisinage,shift_vois(n,2))
    end
    if occursin("t3",vois)
        voisinage = merge(voisinage,shift_vois(n,3))
    end
    if occursin("s1_s1",vois)
        voisinage = merge(voisinage,compose_vois(swap_vois(n,1),swap_vois(n,1)))
    end
    if occursin("s2_s1",vois) || occursin("s1_s2",vois)
        voisinage = merge(voisinage,compose_vois(swap_vois(n,2),swap_vois(n,1)))
    end
    if occursin("s2_s2",vois)
        voisinage = merge(voisinage,compose_vois(swap_vois(n,2),swap_vois(n,2)))
    end
    if occursin("t2_s1",vois) || occursin("s1_t2",vois)
        voisinage = merge(voisinage,compose_vois(shift_vois(n,2),swap_vois(n,2)))
    end
    if Args.get("nbh")==:AUTO
        voisinage = merge(swap_vois(n,1),swap_vois(n,2))
        voisinage = merge(voisinage,shift_vois(n,2))
        voisinage = merge(voisinage,swap_vois(n,3))
    end

    if lg3()
        println("Début de solve : get_stats(sv)=\n", get_stats(sv))
    end

    ln1("\niter <nb_test> = <nb_move>+<nb_unfortunate_try> <movedesc> => bestcost=...")
    # n = sv.inst.nb_planes

    # # Création du voisinage
    # voisinage = merge(swap_vois(n,1),swap_vois(n,2))
    # voisinage = merge(voisinage,shift_vois(n,2))
    # voisinage = merge(voisinage,swap_vois(n,3))

    # voisinage = merge(voisinage,compose_vois(swap_vois(n,1),swap_vois(n,1)))
    # voisinage = merge(voisinage,compose_vois(swap_vois(n,1),shift_vois(n,2)))

    shuffle!(voisinage)

    while !finished(sv)

        
        # Parcourir le voisinage dans un ordre systématique ne semble pas une bonne idée
        # Random.shuffle!(permutations) 
        # Parcours du voisinage
        
        for mut in voisinage.voisins
            sv.nb_test += 1
            copy!(sv.testsol,sv.bestsol)
            permu!(sv.testsol,mut.idx_1,mut.idx_2)
            if sv.testsol.cost < sv.bestsol.cost
                copy!(sv.cursol,sv.testsol)
                if first_best
                    break
                end
            end
        end

        # On met à jour si nécessaire
        if sv.cursol.cost < sv.bestsol.cost
            ln3("\nChangement de voisinage")
            record_bestsol(sv)
            ln3("\n",to_s(sv.bestsol))
            sv.nb_move += 1

        # Sinon c'est qu'on est bloqué dans un optimum (local ou global)
        else 
            sv.blocked = true
        end

    end # fin while !finished
    sv.do_save_bestsol = true
    ln2("END solve!(SteepestSolver)")
    println("="^70)
    record_bestsol(sv)
end

function record_bestsol(sv::SteepestSolver; movemsg = "")
    copy!(sv.bestsol, sv.cursol)
    sv.bestiter = sv.nb_test
    if lg3()
        print("\niter $(rpad(sv.nb_test, 4))= $(sv.nb_move)+$(sv.nb_test-sv.nb_move) ")
        print("$movemsg ")
        print("bestsol=$(to_s(sv.bestsol))")
    elseif lg1()
        print("\niter $(rpad(sv.nb_test, 4))= $(sv.nb_move)+$(sv.nb_test-sv.nb_move) ")
        print("$movemsg => bestcost=", sv.cursol.cost)
    end
    #println("À COMPLÉTER POUR SEQATA !")
end

function get_stats(sv::SteepestSolver)
    txt = """
    ==Etat de l'objet SteepestSolver==
    sv.nb_test=$(sv.nb_test)
    sv.nb_move=$(sv.nb_move)
    sv.blocked=$(sv.blocked)
    sv.duration=$(sv.duration)
    sv.durationmax=$(sv.durationmax)

    sv.testsol.cost=$(sv.testsol.cost)
    sv.cursol.cost=$(sv.cursol.cost)
    sv.bestsol.cost=$(sv.bestsol.cost)
    sv.bestiter=$(sv.bestiter)
    sv.testsol.solver.nb_infeasable=$(sv.testsol.solver.nb_infeasable)
    """
    txt = replace(txt, r"^ {4}" => "")
end

# END TYPE SteepestSolver


# Fonctions liées à la génération de voisinage
using Combinatorics # package de combinatoire

# On représente une permutation par deux listes contenant les indices permutés et leur position image

# Fonction renvoyant les permutations d'éléments 2 à 2 à un certaine distance
function liste_echanges_2_a_2(n::Int,shift::Int=1)
    i_max = n-shift
    echanges = [[[i,i+shift],[i+shift,i]] for i in 1:i_max]
    return(echanges)
end

# Fonction renvoyant toutes les permutations par blocs de taille bloc_size
# L'idée est d'améliorer la solution en ne touchant qu'à un partie de la liste des avions
function liste_blocs_permutation(n::Int,bloc_size::Int = 3)
    i_max = n-bloc_size
    echanges = []
    blocs_permutations = [collect(permutations(collect(i:i+bloc_size))) for i in 1:i_max]
    for blocs in 1:i_max
        idx_1 = blocs_permutations[blocs][1]
        for idx_2 in blocs_permutations[blocs][2:end]
            append!(echanges,[[idx_1,idx_2]])
        end
    end
    return(echanges)
end

    

