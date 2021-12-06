#!/bin/sh
#= La ligne **shell** suivante est un commentaire multiligne ignoré par julia
# mais elle permet de lancer julia avec des options arbitraires
exec julia --project --color=yes --startup-file=no --depwarn=no -- "$0" "$@"
=#

# Pour lancer ce programme en mode interactif depuis un terminal :
#
# Exécution par :
#    julia -iL ./bin/run.jl
#    julia -i --color=yes -L  ./bin/run.jl
# 
# En mode interactif :
#   - le main() n'est pas appelé
#   - on inclue tous les packages et les includes possibles
#   - l'analyse des arguments est faite
#   - on charge le fichier d'utilitaire dédié au mode interactif (src/interactive.jl)
#


# Le realpath est nécessaire si l'un des répertoires parents est un lien symbolique :
this_appdir = dirname(dirname(realpath(@__FILE__())))
using Pkg
Pkg.activate(dirname(dirname(realpath(@__FILE__()))))
Pkg.instantiate()

# @show @__FILE__
# @show PROGRAM_FILE
# @show basename(PROGRAM_FILE)
# @show !empty(PROGRAM_FILE) && realpath(PROGRAM_FILE)
# @show isinteractive()

### TEST PRECOMPILATION START ###
# include("$this_appdir/src/log_util.jl")
# using .Log
# include("$this_appdir/src/args.jl")
# using .Args

### TEST PRECOMPILATION END ###

# ENV["JULIA_USING_ALL"] = 1  # for loading all package
include("$this_appdir/src/Seqata.jl")
using .Seqata

if basename(@__FILE__) == basename(PROGRAM_FILE)
    # Mode d'appel normal : on exécute le programme "bin/xxx.jl"
    if Args.get(:action) in [:none, :help]
        # Exécution normale, mais sans aucun paramètre
        Args.show_usage()
        println("run.jl : AVANT APPEL À main()")
        exit(0)
    end
    main()
else
    @assert(isinteractive())

    @ms using Debugger # chargement du debugger (voir doc)
    @ms using Revise   # fonctionnement à vérifier avec le projet BipSolver
    @ms include("$APPDIR/src/interactive.jl")

    # En mode interactif, on pourrait imposer des arguments par défaut
    Args.set(:infile, "$APPDIR/data/01.alp")

    Log.lg1() && Args.show_args() # car Seqata ne réexporte pas les exports du module Log

    using .Log  # pour se passer du préfixe Log dans Log.lg1() pour la suite

    println()
    println("Début de mode interactif ($(ms()))s")
    println()
end

