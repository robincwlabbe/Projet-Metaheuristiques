using Combinatorics
using Random
export Mutation
export Voisinage
export swap_vois
export shift_vois


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
function clean!(mut::Mutation)
    indices = []
    for i in 1:length(mut.idx_1)
        if mut.idx_1[i]==mut.idx_2[i]
            append!(indices,i)
        end
    end

    # suppression des points fixes
    deleteat!(mut.idx_1,indices)
    deleteat!(mut.idx_2,indices)
    
    # tri de la permutation par idx1 croissant (pour éviter les doublons dans Voisinage)
    order = sortperm(mut.idx_1)
    mut.idx_1 = mut.idx_1[order]
    mut.idx_2 = mut.idx_2[order]
    mut.clean = true
end

# comparer deux permutations
function Base.:(==)(mut1::Mutation, mut2::Mutation)
    bool = (mut1.idx_1==mut2.idx_1) & (mut1.idx_2==mut2.idx_2)
    return(bool)
end



# Voisinages

mutable struct Voisinage
    name::String
    nb_planes::Int
    voisins::Vector{Mutation}
    clean::Bool
    
    function Voisinage(voisins::Vector{Mutation}, name::String = "undef")
        this = new()
        this.name = name
        this.voisins = voisins
        this.nb_planes = voisins[1].nb_planes
        return this
    end

    function Voisinage(vois::Voisinage)
        this = new()
        this.name = copy(vois.name)
        this.voisins = copy(vois.voisins)
        this.nb_planes = copy(vois.nb_planes)
        this.clean = copy(vois.clean)
        return this
    end
end

# supprime les doublons d'un voisinage après avoir clean tous ses voisins
function clean!(voisinage::Voisinage)

    for mut in voisinage.voisins
        if !mut.clean
            clean!(mut)
        end
    end

    indices_empty = []
    n = length(voisinage.voisins)

    for i in 1:n
        if isempty(voisinage.voisins[i].idx_1)
            push!(indices_empty,i)
        end
    end

    deleteat!(voisinage.voisins,indices_empty)
    n = length(voisinage.voisins)
    # pas très efficace mais bon...
    indices = []
    for i in 1:n
        for j in i+1:n
            if voisinage.voisins[i].idx_2 == voisinage.voisins[j].idx_2
                push!(indices,j)
            end
        end
    end

    indices = sort!(unique(indices))
    deleteat!(voisinage.voisins,indices)
    voisinage.clean = true
end

using Random
function shuffle!(voisinage::Voisinage)
    # mélange un voisinage
    # utile si on utilise first break dans SteepestSolver
    Random.shuffle!(voisinage.voisins)
end


function fusion(vois1::Voisinage, vois2::Voisinage)
    # condition pour fusionner les voisinages :
    # - meme nb_planes
    if vois1[1].nb_planes != vois2[1].nb_planes
        throw(DomainError(vois2[1], "nb_planes must be identical in each neighbourhoods"))
    end

    return Voisinage([vois1; vois2])
end


function swap_vois(nb_planes::Int, dist::Int)
    # dist est la "distance" dans l'ordre des avions de la solution actuelle
    # selon laquelle on effectue les swaps. Preferablement, on garde une petite distance
    muts = Mutation[]
    for i in 1:nb_planes-dist
        push!(muts, Mutation(nb_planes, [i,i+dist], [i+dist, i]))
    end
    return Voisinage(muts, string("s", dist))
end


function shift_vois(nb_planes::Int, dist::Int)
    # si dist = 1, meme chose que swap_vois(dist=1)
    # on prend dist >= 2
    muts = Mutation[]
    for i in 1:nb_planes-dist
        # left to right
        push!(muts, Mutation(nb_planes, collect(i:(i+dist)),
            append!(collect((i+1):(i+dist)),i)))
        # right to left
        push!(muts, Mutation(nb_planes, collect(i:(i+dist)),
            append!(Int64[i+dist], collect((i):(i+dist-1)))))
    end
    return Voisinage(muts, string("t", dist))
end


# composition des voisinage (par exemple un shift suivi d'un swap)
function compose_vois(vois1::Voisinage,vois2::Voisinage)
    muts = Mutation[]
    n = vois1.nb_planes
    idx_base = collect(1:n)

    for mut1 in vois1.voisins
        for mut2 in vois2.voisins
            idx_new = collect(1:n)
            idx_new[mut1.idx_1] = idx_new[mut1.idx_2]
            idx_new[mut2.idx_1] = idx_new[mut2.idx_2]
            push!(muts,Mutation(n,copy(idx_base),idx_new))
        end
    end

    composed = Voisinage(muts, string(vois1.name, "_", vois2.name))
    clean!(composed) 

    return composed
end