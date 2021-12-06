export Plane, get_cost_basic, get_cost
export get_cost_basic # seqata
export to_s, to_s_alp, to_s_long

# unexport  to_s_alp_plane_header, to_s_costs

# # Quelques variables globale pour émuler les variables  de class en POO
# current_plane_id = 0

"""
    Plane
 Encapsule les données d'un avion.

 - id: numéro interne commençant en 1, Utilisé pour l'indexation des vecteurs
 - name: nom arbitraire, par exemple le numéro commençant en "p1", "p2", ...
   Mais pour l'instant, c'est un entier pour être conforme à ampl
 - kind: le type de l'avion (car kind est un mot clé réservé en julia !)
 - at: heure d'apparition de l'avion dans l'oeil du radar (inutilisé)
 - lb, target, ub: les heures mini, souhaitées et maxi d'atterrissage
 - ep, tp : heures d'atterrissage au lus tot et ou plus tard

 REMARQUE : le type Plane est IMMUTABLE, il est lié à un avions de
 de l'instance et est défini une fois pour toute.

"""
struct Plane
    id::Int
    name::AbstractString
    kind::Int
    at::Int # appearing time : UNUSED IN SEQATA
    lb::Int # lowest bound = lowest time
    target::Int
    ub::Int # upper bound = upper time
    ep::Float64 # earliness penalty
    tp::Float64 # tardiness penalty

    # Précalul des coûts (de 1 à p.ub)
    # costs::Vector{Float64}
    costs::Tuple{Vararg{Float64}}

    # Constucteur complet avec paramètres passés par association.
    # 
    function Plane(;
            id, name, kind,
            at,
            lb, target, ub, 
            ep, tp,
        )

        @assert lb <= target <= ub

        # On précalcule des coûts réels en fonction de la date d'atterrisasage.
        # Lors de la lecture du coût (par get_cost), les valeur hors borne lb:ub 
        # seront remplacées par une pénanité très élevée (dépendant de viol)
        # 
        # TODO : optimiser la taille du tableaux costs pour éviter de mémoriser 
        # les valeurs en dessous de ub :
        # tmp_costs = fill(BIG_COST, ub-lb+1) # pour optimiser la mémoire utilisée
        # 
        tmp_costs = Vector{Float64}(undef, ub)
        @inbounds for t in lb:ub
            tmp_costs[t] = t < target ? ep * (target - t) : tp * (t - target)
        end

        return new(
            id, name, kind,
            at,
            lb, target, ub, 
            ep, tp,
            Tuple{Vararg{Float64}}(tmp_costs),
        )
    end
end

# Méthode Julia pour convertir tout objet en string (Merci Matthias)
function Base.show(io::IO, p::Plane)
    Base.write(io, to_s(p))
end

# Calcul du coût d'un avion pour une fonction en V
function get_cost_basic(p::Plane, t::Int)
    return t < p.target ? p.ep * (p.target - t) : p.tp * (t - p.target)
end

"""
    get_cost(p::Plane, t::Int; violcost::Float64 = 1000.0)

Retoune le coût de l'avion, éventuellement pénalisé si hors bornes.
"""
@inline function get_cost(p::Plane, t::Int; violcost::Float64 = 1000.0)
    if (t in p.lb:p.ub)
        @inbounds return p.costs[t]
    else
        return violcost * max(p.lb - t, t - p.ub)
    end
end

# return simplement le name. e.g. "p1"
function to_s(p::Plane)
    p.name
end
# return e.g. : "[p1,p2,p3,..,p10]"
function to_s(planes::Vector{Plane})
    # string("[", join( [p.name for p in planes], "," ), "]")
    # string("[", join( (p->p.name).(planes), "," ), "]")
    string("[", join(getfield.(planes, :name), ","), "]")
end

"""
    to_s_alp(p::Plane)

etourne la représentation String de l'avion conforme au format d'instance alp
"""
to_s_alp(p::Plane) = to_s_long(p)
# to_s_alp(p::Plane) = to_s_long(p, format = "alp")
# to_s_alpx(p::Plane) = to_s_long(p, format = "alpx")

function to_s_long(p::Plane)
    io = IOBuffer()
    print(io, "plane ")
    print(io, lpad(p.name, 3), " ")
    print(io, lpad(p.kind, 4), " ")
    print(io, lpad(p.at, 5), " ")
    print(io, lpad(p.lb, 5), " ")
    print(io, lpad(p.target, 5), " ")
    print(io, lpad(p.ub, 5), "    ")
    print(io, lpad(p.ep, 4), " ")
    print(io, lpad(p.tp, 4), " ")
    String(take!(io))
end
# Retourne un commentaire décrivant une ligne au forme alp ou alpx
# Attention : pour le projet Seqata, seul le format alp existe)
# soit: #    name  kind   at     E     T     L    ep    tp
# soit: #    name  kind   at     E     T     L    dt1 cost1   dt2 cost2 ...
# Il n'y a pas de return final
#
function to_s_alp_plane_header()
    io = IOBuffer()
    print(io, "#    name  kind   at     E     T     L")
    print(io, "    ep    tp ")
    String(take!(io))
end

# Affiche les éléments définis ( != -1 ) du tableau précalculé costs 
# - d'une part les costs précalculés en chaque date
# - d'autre part les coûts calculés sur demande pour des dates arbitraires
#   (et mémoïsés)
#
function to_s_costs(p::Plane)
    io = IOBuffer()
    print(io, p.name, "=>costs[]= ")
    for t = 1:length(p.costs)
        p.costs[t] <= -1.0 && continue
        print(io, " ", t, ":", p.costs[t])
    end
    String(take!(io))
end
