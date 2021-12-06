export main_stats

"""
    main_stats()
Méthode principale d'exécution de l'action `stats`.

Cette méthode lit l'instance.
Si ne niveau de verbosité est suffisant, réaffiche l'instance dans
différent format (dont AMPL).
Dans tous les cas des statistiques sur l'instance sont affichées.
"""
function main_stats()
    println("="^70)
    println("Début de l'action stats\n")
    inst = Instance(Args.get(:infile))

    if lg3()
        println("="^70)
        println("Regéneration de l'instance au format ampl")
        println(to_s_long(inst, format = "ampl"))
        println("="^70)
        println("Regéneration de l'instance au format alp")
        println(to_s_long(inst, format = "alp"))
        println("="^70)
        println("Regéneration de l'instance au format alpx")
        println(to_s_long(inst, format = "alpx"))
    end

    println("="^70)
    println(to_s_stats(inst))
    # println("...")
    #
    # println("="^70)
    # println("Vérification de l'inégalité triangulaire de l'instance")
    # print_triangular_inequality_viols(inst; doprint=true)

    println("Fin de l'action stats")
end
