@ms include("greedy_solver.jl")

export main_greedy

function main_greedy()
    println("="^70)
    println("Début de l'action greedy")

    ### Contruction de l'instance
    inst = Instance(Args.get(:infile))

    ### Extraction et positionnenement des paramètres
    # Args.show_args() # pour voir toutes les options

    # Si l'option itermax vaut 0 (i.e automatique) on ne fera qu'une seule itération
    itermax = Args.get(:itermax) == 0 ? 1 : Args.get(:itermax)

    # Si l'option rcl_size vaut 0 (i.e automatique) on choisira le glouton déterministe
    rcl_size = Args.get(:rcl_size) == 0 ? 1 : Args.get(:rcl_size)

    ### Initialisation des objets Solution
    cursol = Solution(inst, update = false)
    bestsol = Solution(inst, update = false)
    
    ### Construction et résolution du solveur chronométré
    ms_start = ms() # en seconde depuis le démarrage avec précision à la ms
    sv = GreedySolver(inst)
    solve!(sv, itermax=itermax, rcl_size=rcl_size)
    ms_stop = ms()

    ### Lecture et exploitation de la solution
    bestsol = sv.bestsol
    write(bestsol)
    # le print_sol final n'est exécuté que si lg1() retourne true
    lg1() && print_sol(bestsol)

    ### Affichage des statistiques
    nb_calls = bestsol.solver.nb_calls
    nb_infeasable = bestsol.solver.nb_infeasable
    nb_sec = round(ms_stop - ms_start, digits = 3)
    nb_call_per_sec = round(nb_calls / nb_sec, digits = 3)
    println("Performance: ")
    println("  nb_calls=$nb_calls")
    println("  nb_infeasable=$nb_infeasable")
    println("  nb_sec=$nb_sec")
    println("  => nb_call_per_sec = $nb_call_per_sec call/sec")

    println("Fin de l'action greedy")
end
