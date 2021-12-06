export LpTimingSolver, symbol, solve!

# Déclaration des packages utilisés dans ce fichier
# certains sont déjà chargés dans le fichier usings.jl

"""
    LpTimingSolver

Résoud du Sous-Problème de Timing par programmation linéaire.

Ce solveur résoud le  sous-problème de timing consistant à trouver les dates
optimales d'atterrissage des avions à ordre fixé.
Par rapport aux autres solvers (e.g DescentSolver, AnnealingSolver, ...), il
ne contient pas d'attribut bestsol

VERSION -t lp4 renommé en Lp : modèle diam version sans réoptimisation (coldrestart)
  - modèle diam simplifié par rapport à lp3 : sans réoptimisation (coldrestart)
  - pas de réoptimisation : on recrée le modèle à chaque nouvelle permu
    d'avion dans le solver
  - seules les contraintes de séparation nécessaires à la permu sont créées
  - gestion de l'option --assume_trineq true|false (true par défaut, cf lp1)
  - contraintes de coût simple (diam) : une seule variable de coût par avion
    plus un contrainte par segment :
       cost[i] >= tout_segment[i]
"""
mutable struct LpTimingSolver
    inst::Instance
    # Les attributs spécifiques au modèle
    model::Model  # Le modèle MIP
    x         # vecteur des variables d'atterrissage
    cost      # variable du coût de la solution
    costs     # variables du coût de chaque avion

    nb_calls::Int    # POUR FAIRE VOS MESURES DE PERFORMANCE !
    nb_infeasable::Int

    # Le constructeur
    function LpTimingSolver(inst::Instance)
        this = new()

        this.inst = inst

        # Création et configuration du modèle selon le solveur externe sélectionné
        this.model = new_lp_model() # SERA REGÉNÉRÉ DANS CHAQUE solve!()

        this.nb_calls = 0
        this.nb_infeasable = 0

        return this
    end
end

# Permettre de retrouver le nom de notre XxxxTimingSolver à partir de l'objet
function symbol(sv::LpTimingSolver)
    return :lp
end

function solve!(sv::LpTimingSolver, sol::Solution)

    error("\n\nMéthode solve!(sv::LpTimingSolver, ...) non implanté : AU BOULOT :-)\n\n")

    sv.nb_calls += 1

    #
    # 1. Création du modèle spécifiquement pour cet ordre d'avion de cette solution
    #

    sv.model = new_lp_model()

    # À COMPLÉTER : variables ? contraintes ? ...

    # ...


    # 2. résolution du problème à permu d'avion fixée
    #
    JuMP.optimize!(sv.model)

    # 3. Test de la validité du résultat et mise à jour de la solution
    if JuMP.termination_status(sv.model) == MOI.OPTIMAL
        # tout va bien, on peut exploiter le résultat

        # 4. Extraction des valeurs des variables d'atterrissage

        # ATTENTION : les tableaux x et costs sont dans l'ordre de
        # l'instance et non pas de la solution !
        for (i, p) in enumerate(sol.planes)
            sol.x[i] = round(Int, value(sv.x[p.id]))
            # Cet arrondi permet d'utiliser le solver linéaire Tulip qui utilise
            # une méthode de points intérieurs et qui contrairement au simplexe, 
            # ne donne pas nécessairement une solution située sur un point extrème
            # du polytope des contraintes.
            # Cela est possible car pour toutes les instances, les pénalités 
            # unitaire sont exprimées en centièmes.
            # sol.costs[i] = value(sv.costs[p.id])
            sol.costs[i] = round(value(sv.costs[p.id], digits=2))
        end
        prec = Args.get(:cost_precision)
        sol.cost = round(value(sv.cost), digits = prec)

    else
        # La solution du solver est invalide : on utilise le placement au plus
        # tôt de façon à disposer malgré tout d'un coût pénalisé afin de pouvoir
        # continuer la recherche heuristique de solutions.
        sv.nb_infeasable += 1
        solve_to_earliest!(sol)
    end

    # println("END solve!(LpTimingSolver, sol)")
end
