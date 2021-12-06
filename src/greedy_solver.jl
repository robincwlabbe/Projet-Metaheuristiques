export GreedySolver
export solve_one!, solve!
export reset!

mutable struct GreedySolver
    inst::Instance
    cursol::Solution      # Solution courante
    bestsol::Solution     # meilleure Solution rencontrée
    do_save_bestsol::Bool
    GreedySolver() = new() # Constructeur par défaut
end

function GreedySolver(inst::Instance)
    ln3("Début constructeur de GreedySolver")
    this = GreedySolver() # Appel le constructeur par défaut
    this.inst = inst
    this.cursol = Solution(this.inst, update=false)
    this.bestsol = Solution(this.inst, update=false)
    this.do_save_bestsol = true
    return this
end

function reset!(sv::GreedySolver)
    sv.cursol.cost = Inf
    sv.bestsol.cost = Inf
end

# solve_determinist! : résoud le glouton déterministe
function solve_determinist!(sv::GreedySolver)
    ln3("BEGIN solve_determinist!(GreedySolver)")

    # 
    error("\n\nAction Greedy/solve_determinist() non implanté : AU BOULOT :-)\n\n")
    # 

    ln3("END solve_determinist!(GreedySolver)")
end


# solve_one! : résoud **une** itération du glouton randommisé
function solve_one!(sv::GreedySolver; rcl_size = 1)
    ln4("BEGIN solve_one!(GreedySolver)")

    #
    error("\n\nAction Greedy/solve_one!() non implanté : AU BOULOT :-)\n\n")
    #

    ln4("\nEND solve_one!(GreedySolver)")
end

# solve!
# - une seule itération par défaut (itermax==1)
# - version déterministe par défait (rcl_size==1)
function solve!(sv::GreedySolver; itermax::Int = 1, rcl_size::Int = 1)
    ln2("BEGIN solve!(GreedySolver)")
    if rcl_size == 1
        # Quelque soit itermax, on ne fait qu'un seul glouton déterministe
        return solve_determinist!(sv)
    end
    for i = 1:itermax
        solve_one!(sv, rcl_size=rcl_size)
        if sv.cursol.cost < sv.bestsol.cost
            copy!(sv.bestsol, sv.cursol)
            write(sv.bestsol)
            lg3("\n") # Pour séparer l'affichage de bestsol des "." précédents
            record_bestsol(sv, i)
        else
            lg3(".")
        end
    end
    ln2("\nEND solve!(GreedySolver)")
end

function record_bestsol(sv::GreedySolver, iter = -1)
    copy!(sv.bestsol, sv.cursol)
    if sv.do_save_bestsol
        write(sv.bestsol)
    end
    if lg3()
        print("\niter=$iter ")
        print("bestsol=$(to_s(sv.bestsol))")
    elseif lg1()
        print("\niter=$iter ")
        print("bestcost=", sv.bestsol.cost)
    end
end
