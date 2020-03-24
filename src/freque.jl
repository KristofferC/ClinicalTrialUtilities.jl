

struct ConTab{Int32, Int32}
    tab::Matrix{Int}
    row::Vector
    col::Vector

    function ConTab(m::Matrix{Int})
        row = Vector{Symbol}(undef, size(m, 1)) .= Symbol("")
        col = Vector{Symbol}(undef, size(m, 2)) .= Symbol("")
        new{size(m, 1), size(m, 2)}(m, row, col)
    end
    function ConTab(m::Matrix{Int}, row, col)
        new{size(m, 1), size(m, 2)}(m, row, col)
    end
end

struct Freque
    val
    n
end


function freque(data::DataFrame; vars::Symbol, alpha = 0.05)::DataFrame
    result = DataFrame(value = Any[], n = Int[], p = Float64[], cil = Float64[], ciu = Float64[])
    list   = unique(data[:, vars])
    n      = length(data[:, vars])
    for i in list
        ne = count(x -> (x == i), data[:, vars])
        pe = ne/n
        ci = ClinicalTrialUtilities.propci(ne, n, alpha=alpha, method=:wald)
        push!(result, [i, ne, pe, ci.lower, ci.upper])
    end
    return result
end

function contab(data::DataFrame; row::Symbol, col::Symbol)::ConTab
    clist = unique(data[:, col])
    rlist = unique(data[:, row])
    cn    = length(clist)
    rn    = length(rlist)
    dfs   = Matrix{Int}(undef, rn, cn)
    for ri = 1:rn
        rowl  = data[data[:, row] .== rlist[ri], col]
        for ci = 1:cn
            cnt = count(x -> x == clist[ci], rowl)
            dfs[ri, ci] = cnt
        end
    end
    return ConTab(dfs, rlist, clist)
end


function pirson(a::Matrix{Int})
    n   = length(a[:,1])
    m   = length(a[1,:])
    tm  = sum(a, dims=1)[1,:]
    tn  = sum(a, dims=2)[:,1]
    num = sum(tm)
    ae  = Array{Real, 2}(undef, n, m)
    for im = 1:m
        for in = 1:n
            ae[in, im] = tn[in]*tm[im]/num
        end
    end
    chsq  = sum(((a .- ae) .^2 ) ./ ae)
    chsqy = sum(((abs.((a .- ae)) .- 0.5) .^2 ) ./ ae)
    ml    = 2 * sum( a .* log.( a ./ ae ))
    df    = (n - 1)*(m - 1)
    ϕ     = sqrt(chsq / (num*(n - 1)*(m - 1)))
    C     = sqrt(chsq/(chsq+num))
    K     = sqrt(chsq/num/sqrt((n - 1)*(m - 1)))
    return chsq, chsqy, ml, 1-cdf(Chisq(df), chsq)
end

function fisher(a::Matrix{Int})
    dist  = Hypergeometric(sum(a[1, :]), sum(a[2, :]), sum(a[:, 1]))
    value = min(2 * min(cdf(dist, a[1, 1]), ccdf(dist, a[1, 1])), 1.0)
end


function fisher(t::ConTab{2, 2})
    fisher(t.tab)
end


function mcnmtest(a::Matrix{Int}; cc = false)
    if cc cc = 1 else cc = 0 end
    (abs(a[1,2] - a[2,1]) - cc) ^ 2 / (a[1,2] + a[2,1])

end
#=
function StatsBase.confint(t::ConTab{2, 2})
end
=#
