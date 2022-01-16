using Combinatorics
export Mutation

# Mutations

mutable struct Mutation
    nb_planes::Int
    idx_1::Vector{Int} # doit être trié par ordre croissant, cela permettra de comparer les permutations
    idx_2::Vector{Int}
    clean::Bool # pour savoir si on a déjà vérifié qu'une solution était propre
                # permet d'éviter de vérifier inutilement qu'une solution est propre
                # par exemple si elle l'est pas Construction


    function Mutation(nb_planes::Int, idx_1::Vector{Int},
        idx_2::Vector{Int}, clean::Bool = false)
        this = new()

        # Il faut veiller à supprimer les points fixes

        this.clean = false
        this.idx_1 = idx_1
        this.idx_2 = idx_2
        this.nb_planes = nb_planes
        return this
    end


    function Mutation(mut::Mutation)
        this = new()
        this.idx_1 = copy(mut.idx_1)
        this.idx_2 = copy(mut.idx_2)
        this.nb_planes = copy(mut.nb_planes)
        this.clean = copy(mut.clean)
        return this
    end
end


# supprime les points fixes d'une mutation
function clear!(mut::Mutation)
    indices = []
    for i in 1:mut.nb_planes
        if mut.idx_1[i]==mut.idx_2[i]
            append!(indices,i)
        end
    end
    splice!(mut.idx_1,indices)
    splice!(mut.idx_2,indices)
    mut.nb_planes = length(mut.idx_1)
    mut.clean = true
end

# comparer deux permutations
function Base.:(==)(mut1::Mutation, mut2::Mutation)
    bool = (mut1.idx_1==mut2.idx_1) & (mut1.idx_2==mut2.idx_2)
    return(bool)
end



# Voisinages

mutable struct Voisinage
    voisins::Vector{Mutation}

    function Voisinage(voisins::Vector{Mutation})
        this = new()
        this.voisins = voisins
    end

    function Voisinage(vois::Voisinage)
        this = new()
        this.voisins = copy(vois.voisins)
    end
end

function clear!(voisinage::Voisinage)
    # supprime les doublons dans le voisinage
    # éventuellement vérifie que chaque mutations du voisinage est clean
    # si une solution n'est pas clean on la nettoie
end

function shuffle!(voisinage::Voisinage)
    # mélange un voisinage
end

function swap_vois(nb_planes::Int, dist::Int)
    # dist est la "distance" dans l'ordre des avions de la solution actuelle
    # selon laquelle on effectue les swaps. Preferablement, on garde une petite distance
    muts = Mutation[]
    for i in 1:nb_planes-dist
        push!(muts, Mutation(nb_planes, [i,i+dist], [i+dist, i]))
    end
    return Voisinage(muts)
end

function shift_vois(nb_planes::Int, dist::Int)
    muts = Mutation[]
    for i in 1:nb_planes-dist
        # left to right
        push!(muts, Mutation(nb_planes, collect(i:(i+dist)),
            append!(collect((i+1):(i+dist)),i)))
        # right to left
        push!(muts, Mutation(nb_planes, collect(i:(i+dist)),
            append!(Int64[i+dist], collect((i):(i+dist-1)))))
    end
    return Voisinage(muts)
end