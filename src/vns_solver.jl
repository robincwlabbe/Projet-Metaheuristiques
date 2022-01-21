export VnsSolver

"""
VnsSolver

Résoud le problème global par méthode à voisinage variable.

"""
mutable struct VnsSolver
    inst::Instance
    nb_test::Int          # Nombre total de voisins testé
    nb_move::Int          # nombre de voisins acceptés 

    duration::Float64     # durée réelle (mesurée) de l'exécution
    durationmax::Float64  # durée max de l'exécution (--duration)
    starttime::Float64    # heure de début d'une résolution

    cursol::Solution      # Solution courante
    bestsol::Solution     # meilleure Solution rencontrée
    testsol::Solution     # nouvelle solution potentielle
    full_expl::Bool       # indique si l'on passe à la premiere solution
                          # ameliorante ou si l'on explore tout le voisinage

    bestiter::Int
    do_save_bestsol::Bool
    blocked::Bool         # indique si tous les voisinages testés ne 
                          # sont pas améliorants : on s'arrête
    VnsSolver() = new() # Constructeur par défaut (sans paramètre)
end

function VnsSolver(inst::Instance; startsol::Union{Nothing,Solution} = nothing)
    ln3("Début constructeur de VnsSolver")

    this = VnsSolver()
    this.inst = inst

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
            println("Dans VnsSolver : this.cursol = this.opts[:startsol] ")
            println("this.cursol", to_s(this.cursol))
        end
    end
    this.bestsol = Solution(this.cursol)
    this.testsol = Solution(this.cursol)
    this.blocked = false
    this.do_save_bestsol = false
    this.full_expl = true

    return this
end

# Retourne true ssi l'état justifie l'arrêt de l'algorithme
#
function finished(sv::VnsSolver)
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
    sv::VnsSolver;
    startsol::Union{Nothing,Solution} = nothing,
    durationmax::Int = 300
)
    ln2("BEGIN solve!(VnsSolver)")
    println("\nFull exploration mode : ", sv.full_expl)
    if durationmax != 0
        sv.durationmax = durationmax
    end
    if startsol != nothing
        sv.cursol = startsol
        copy!(sv.bestsol, sv.cursol) # on réinitialise bestsol à cursol
        copy!(sv.testsol, sv.cursol)
        if lg2()
            println("Dans VnsSolver : sv.cursol = sv.opts[:startsol] ")
            println("sv.cursol : ", to_s(sv.cursol))
        end
    else
        # on garde la dernière solution sv.cursol
    end
    sv.starttime = time_ns() / 1_000_000_000
    
    if lg3()
        println("Début de solve : get_stats(sv)=\n", get_stats(sv))
    end

    ln1("\niter <nb_test> nb_move <nb_move> => bestcost=...")
    n = sv.inst.nb_planes
    s1 = swap_vois(n,1)
    voisinages = [s1,
                  swap_vois(n,2),
                  shift_vois(n,2),
                  swap_vois(n,3),
                  shift_vois(n,3),
                  compose_vois(s1,s1)]

    sv.nb_move=0
    while !finished(sv)
        
        # Parcourir les voisinages successifs
        # si aucune solution ameliorante n'a été trouvée, on passe au prochain.
        # Une fois qu'on a parcouru tous les voisinages pour une solution
        # courante donnée sans trouver d'améliorations, on s'arrête.
        println("\n")
        for voisinage in voisinages
            println(voisinage.name)
            for mut in voisinage.voisins
                copy!(sv.testsol, sv.cursol) # on repart de la solution courante
                sv.nb_test += 1
                permu!(sv.testsol, mut.idx_1, mut.idx_2)

                if sv.testsol.cost < sv.cursol.cost
                    if sv.full_expl == true
                        # on continue à explorer tout le voisinage
                        # en enregistrant la meilleure solution rencontrée
                        if sv.testsol.cost < sv.bestsol.cost
                            copy!(sv.bestsol, sv.testsol)
                        end
                    else
                        # on passe à la nouvelle solution courante
                        copy!(sv.bestsol, sv.testsol)
                        break
                    end
                end
            end
            if sv.bestsol.cost < sv.cursol.cost
                # si on a trouvé une meilleure solution dans ce voisinage
                # on sort de la boucle et on recommence pour la nouvelle
                # solution courante
                break
            end
            # sinon, on continue jusqu'à la fin de la boucle
        end
        if sv.bestsol.cost < sv.cursol.cost
            #println("\nChangement de voisinage")
            #println("\nNombre d'iterations : ", sv.nb_test)
            #println("\nCoût de la meilleure solution : ", sv.bestsol.cost)
            copy!(sv.cursol,sv.bestsol)
            sv.nb_move += 1
            if lg3()
                print("\niter $(rpad(sv.nb_test, 6))")
                print(" nb_move $(rpad(sv.nb_move, 3)) => ")
                print("bestsol=$(to_s(sv.bestsol))")
            elseif lg1()
                print("\niter $(rpad(sv.nb_test, 6))")
                print(" nb_move $(rpad(sv.nb_move, 3)) => ")
                print("bestcost=", sv.cursol.cost)
            end
        else
            # on a parcouru tous les voisinages sans trouver de meilleures solutions
            sv.blocked = true
        end

    end # fin while !finished

    ln2("END solve!(VnsSolver)")
    println("="^70)
    println("\n",to_s(sv.bestsol))
end

function get_stats(sv::VnsSolver)
    txt = """
    ==Etat de l'objet VnsSolver==
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