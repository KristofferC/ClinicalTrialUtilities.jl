
module CI
    using Distributions
    import ClinicalTrialUtilities.ZDIST
    import ClinicalTrialUtilities.CTUException
    #const ZDIST = Normal()
    export oneProp, oneMeans, twoProp, twoMeans, ConfInt

    struct ConfInt
        lower::Float64
        upper::Float64
        estimate::Float64
    end

    function oneProp(x, n; alpha=0.05, method="wilson")
        if method=="wilson"
            return propWilsonCI(x, n, alpha)
        elseif method=="cp"
            return propCPCI(x, n, alpha)
        elseif method=="soc"
            return propSOCCI(x, n, alpha)
        elseif method=="blaker"
            return propBlakerCI(x, n, alpha)
        elseif method=="arcsine"
            return propARCCI(x, n, alpha)
        elseif method=="wald"
            return propWaldCI(x, n, alpha)
        end
    end

    function oneMeans(m,s,n,alpha; method="tdist")
        if method=="norm"
            meanNormCI(m,s,n,alpha)
        elseif method=="tdist"
            meanTdistCI(m,s,n,alpha)
        end
    end

    function twoProp(x1, n1, x2, n2; alpha=0.05, type="", method="")

        if type=="diff"
            if method == "nhs"
                return propDiffNHSCI(x1, n1, x2, n2, alpha)
            elseif method == "ac"
                return propDiffACCI(x1, n1, x2, n2, alpha)
            elseif method == "mn"
                return propDiffMNCI(x1, n1, x2, n2, alpha)
            end
        elseif type=="rr"
            if method == "cli"
                return propRRCLICI(x1, n1, x2, n2, alpha)
            elseif method == "mover"
                return  propRRMOVERCI(x1, n1, x2, n2, alpha)
            end
        elseif type=="or"
            if method=="mn"
                return propORCI(x1, n1, x2, n2, alpha)
            elseif method=="awoolf"
                return propORaWoolfCI(x1, n1, x2, n2, alpha)
            elseif method=="woolf"
                return propORWoolfCI(x1, n1, x2, n2, alpha)
            elseif method=="exact"

            end
        end
    end #twoProp

    function twoMeans(m1::Real, s1::Real, n1::Real, m2::Real, s2::Real, n2::Real; alpha::Real=0.05, type="diff", method="ev")::ConfInt
        if type=="diff"
            if method == "ev"
                return meanDiffEV(m1::Real, s1::Real, n1::Real, m2::Real, s2::Real, n2::Real, alpha::Real)
            elseif method == "uv"
                return meanDiffUV(m1::Real, s1::Real, n1::Real, m2::Real, s2::Real, n2::Real, alpha::Real)
            end
        elseif type=="ratio"
            return
        end
    end #twoMeans

    #-----------------------------PROPORTIONS-----------------------------------

    #Wilson’s confidence interval for a single proportion
    #Wilson, E.B. (1927) Probable inference, the law of succession, and statistical inferenceJ. Amer.Stat. Assoc22, 209–212
    function propWilsonCI(x, n, alpha)::ConfInt
        z = abs(quantile(ZDIST, 1-alpha/2))
        p = x/n
        b = (z*((p*(1-p)+(z^2)/(4*n))/n)^(1/2))/(1+(z^2)/n)
        m = (p+(z^2)/(2*n))/(1+(z^2)/n)
        return ConfInt(m - b,m + b,m)
    end
    #Clopper-Pearson exatct CI
    #Clopper, C. and Pearson, E.S. (1934) The use of confidence or fiducial limits illustrated in the caseof the binomial.Biometrika26, 404–413.
    function propCPCI(x, n, alpha)::ConfInt
        if x==0
            ll=0.0
            ul=1.0-(alpha/2)^(1/n)
        elseif x==n
            ul=1.0
            ll=(alpha/2)^(1/n)
        else
            ll = 1/(1+(n-x+1)/(x*quantile(FDist(2*x, 2*(n-x+1)), alpha/2)))
            ul = 1/(1+(n-x) / ((x+1)*quantile(FDist(2*(x+1), 2*(n-x)), 1-alpha/2)))
        end
        return ConfInt(ll, ul, x/n)
    end
    #Blaker, H. (2000). Confidence curves and improved exact confidence intervals for discrete distribu-tions,Canadian Journal of Statistics28 (4), 783–798
    function propBlakerCI(x, n, alpha)::ConfInt
        tol = 1E-5
        lower = 0
        upper = 1
        if n != 0
            lower = quantile(Beta(x, n-x+1), alpha/2)
            while acceptbin(x, n, lower+tol) < alpha
                lower +=tol
            end
        end
        if x != n
            upper = quantile(Beta(x+1, n-x), 1-alpha/2)
            while acceptbin(x, n, upper-tol) < alpha
                upper -=tol
            end
        end
        return ConfInt(lower,upper, x/n)
    end
    @inline function acceptbin(x,n,p)
        BIN = Binomial(n,p)
        p1 = 1-cdf(BIN,x-1)
        p2 =   cdf(BIN,x)
        a1 = p1 + cdf(BIN, quantile(BIN,p1)-1)
        a2 = p2+1-cdf(BIN, quantile(BIN,1-p2))
        return min(a1,a2)
    end
    #Wald
    function propWaldCI(x, n, alpha)::ConfInt
        p=x/n
        b = quantile(ZDIST, 1-alpha/2)*sqrt(p*(1-p)/n)
        return ConfInt(p-b,p+b,p)
    end
    #SOC  Second-Order corrected
    #T. Tony Cai One-sided con&dence intervals in discretedistributions doi:10.1016/j.jspi.2004.01.00
    #not clear implementation
    function propSOCCI(x, n, alpha)::ConfInt
        p  = x/n
        k  = quantile(ZDIST, 1-alpha/2)
        k2 = k^2
        η  = k2/3+1/6
        γ1 = -(k2*13/18+17/18)
        γ2 = k2/18+7/36
        m  = (x+η)/(n+2*η)
        b  = k*sqrt(p*(1-p)+(γ1*p*(1-p)+γ2)/n)/sqrt(n)
        return ConfInt(m-b, m+b, p)
    end

    #Arcsine
    function propARCCI(x,n,alpha)::ConfInt
        q = quantile(ZDIST, 1-alpha/2)
        p = x/n
        z = q/(2*sqrt(n))
        return ConfInt(sin(asin(sqrt(p))-z)^2, sin(asin(sqrt(p))+z)^2, p)
    end
    #--------------------------------OR-----------------------------------------
    #Cornfield, J. (1956) A statistical problem arising from retrospective studies.  In Neyman J. (ed.),Proceedings of the third Berkeley Symposium on Mathematical Statistics and Probability4,  pp.135–148.
    #Miettinen O. S., Nurminen M. (1985) Comparative analysis of two rates.Statistics in Medicine4,213–226
    #Agresti, A. 2002. Categorical Data Analysis. Wiley, 2nd Edition.
    #MN Score
    function propORCI(x1::Int, n1::Int, x2::Int, n2::Int, alpha::Float64)::ConfInt
        px = x1/n1
        py = x2/n2
        if (x1==0 && x2==0) || (x1==n1 && x2==n2)
            ul    = Inf
            ll    = 0
        elseif x1==0 || x2==n2
            ll    = 0
            theta = 0.01/n2
            ul    = limit(x1,n1,x2,n2,alpha, theta, 1)
        elseif x1==n1 || x2 == 0
            ul    = Inf
            theta = 100*n1
            ll    = limit(x1,n1,x2,n2,alpha, theta, 0)
        else
            theta = px/(1-px)/(py/(1-py))/1.1
            ll    = limit(x1,n1,x2,n2,alpha,theta,0)
            theta = px/(1-px)/(py/(1-py))*1.1
            ul    = limit(x1,n1,x2,n2,alpha,theta,1)
        end
        return ConfInt(ll, ul, (px/(1-px))/(py/(1-py)))
    end
    @inline function limit(x1, n1, x2, n2, alpha, lim, t)
        z  = quantile(Chisq(1), 1-alpha)
        ci::Float64 = 0
        px = x1/n1
        score = 0
        while score < z
            a = n2*(lim-1)
            b = n1*lim+n2-(x1+x2)*(lim-1)
            c = -(x1+x2)
            p2d = (-b+sqrt(b^2-4*a*c))/(2*a)
            p1d = p2d*lim/(1+p2d*(lim-1))
            score = ((n1*(px-p1d))^2)*(1/(n1*p1d*(1-p1d))+1/(n2*p2d*(1-p2d)))*(n1+n2-1)/(n1+n2)
            ci = lim
            if t==0 lim = ci/1.001 else lim = ci*1.001 end
        end
        return ci
    end #limit

    #Adjusted Woolf interval (Gart adjusted logit) Lawson, R (2005):Smallsample confidence intervals for the odds ratio.  Communication in Statistics Simulation andComputation, 33, 1095-1113.
    function propORaWoolfCI(x1::Int, n1::Int, x2::Int, n2::Int, alpha::Float64)::ConfInt
            xa = x1 + 0.5
            xb = n1 - x1 + 0.5
            xc = x2 + 0.5
            xd = n2 - x2 + 0.5
            estimate = xa*xd/xc/xb
            estI = log(estimate)
            stde = sqrt(1/xa + 1/xb + 1/xc + 1/xd)
            z   = quantile(ZDIST, 1-alpha/2)
            return ConfInt(exp(estI - z*stde), exp(estI + z*stde), estimate)
    end
    #Woolf logit
    function propORWoolfCI(x1::Int, n1::Int, x2::Int, n2::Int, alpha::Float64)::ConfInt
            xa = x1
            xb = n1 - x1
            xc = x2
            xd = n2 - x2
            estimate = xa*xd/xc/xb
            estI = log(estimate)
            stde = sqrt(1/xa + 1/xb + 1/xc + 1/xd)
            z   = quantile(ZDIST, 1-alpha/2)
            return ConfInt(exp(estI - z*stde), exp(estI + z*stde), estimate)
    end




    #------------------------------DIFF-----------------------------------------

    #Newcombes Hybrid Score interval for the difference of proportions
    function propDiffNHSCI(x1::Int, n1::Int, x2::Int, n2::Int, alpha::Float64)::ConfInt
        p1 = x1/n1
        p2 = x2/n2
        estimate = p1-p2
        q = quantile(ZDIST, 1 - alpha/2)
        ci1 = propWilsonCI(x1, n1, alpha)
        ci2 = propWilsonCI(x2, n2, alpha)
        return ConfInt(estimate-q*sqrt(ci1.lower*(1-ci1.lower)/n1+ci2.upper*(1-ci2.upper)/n2),
                       estimate+q*sqrt(ci1.upper*(1-ci1.upper)/n1+ci2.lower*(1-ci2.lower)/n2), estimate)
    end
    #Agresti-Caffo interval for the difference of proportions
    function propDiffACCI(x1::Int, n1::Int, x2::Int, n2::Int, alpha::Float64)::ConfInt
        p1       = x1/n1
        p2       = x2/n2
        estimate = p1-p2
        q        = quantile(ZDIST, 1 - alpha/2)
        p1I      = (x1+1)/(n1+2)
        p2I      = (x2+1)/(n2+2)
        n1I      = n1+2
        n2I      = n2+2
        estI     = p1I-p2I
        stderr   = sqrt(p1I*(1-p1I)/n1I+p2I*(1-p2I)/n2I)
        return ConfInt(estI-q*stderr, estI+q*stderr, estimate)
    end
    #Method of Mee 1984 with Miettinen and Nurminen modification nxy / (nxy - 1) Newcombe 1998
    function propDiffMNCI(x1::Int, n1::Int, x2::Int, n2::Int, alpha::Float64)::ConfInt
        p1    = x1/n1
        p2    = x2/n2
        z     = quantile(Chisq(1), 1-alpha)
        score = 0
        proot = p1 - p2
        dp    = 1 - proot
        up2   = 0
        while dp > 0.0000001 && abs(z-score) > 0.000001
            dp    = dp/2
            up2   = proot + dp
            score = zstat(p1, n1, p2, n2, up2)
            if score < z proot = up2 end
        end
        proot = p1-p2
        dp    = 1 + proot
        low2  = 0
        while dp > 0.0000001 && abs(z-score) > 0.000001
            dp    = dp/2
            low2  = proot - dp
            score = zstat(p1, n1, p2, n2, low2)
            if score < z proot = low2 end
        end
        return ConfInt(low2, up2, p1-p2)
    end
    @inline function zstat(p1x::Float64, nx::Int, p1y::Float64, ny::Int, dif::Float64)::Float64
        diff       = p1x-p1y-dif
        if abs(diff) == 0
            fmdiff = 0
        else
            t      = ny/nx
            a      = 1+t
            b      = -(1+t+p1x+t*p1y+dif*(t+2))
            c      = dif*dif+dif*(2*p1x+t+1)+p1x+t*p1y
            d      = -p1x*dif*(1+dif)
            v      = (b/a/3)^3-b*c/(6*a*a)+d/a/2
            s      = sqrt((b/a/3)^2-c/a/3)
            if v > 0 u = s else u = -s end
            w      = (pi+acos(v/u^3))/3
            p1d    = 2*u*cos(w)-b/a/3
            p2d    = p1d - dif
            nxy    = nx + ny
            var    = (p1d*(1-p1d)/nx+p2d*(1-p2d)/ny)*nxy/(nxy-1)
            fmdiff = diff^2/var
        end
        return fmdiff
    end
    #--------------------------------RR-----------------------------------------
    #Miettinen-Nurminen Score interval
    #Not implemented
    function propRRMNCI(x1::Int, n1::Int, x2::Int, n2::Int, alpha::Float64) end

    #Crude log interval
    #Gart, JJand Nam, J (1988): Approximate interval estimation of the ratio of binomial parameters: Areview and corrections for skewness. Biometrics 44, 323-338.
    function propRRCLICI(x1::Int, n1::Int, x2::Int, n2::Int, alpha::Float64)::ConfInt
        x1I  = x1+0.5
        x2I  = x2+0.5
        n1I  = n1+0.5
        n2I  = n2+0.5
        estI = log((x1I/n1I)/(x2I/n2I))
        stderrlog = sqrt(1/x2I+1/x1I-1/n2I-1/n1I)
        estimate  = (x1/n1)/(x2/n2)
        Z         =  quantile(ZDIST,1-alpha/2)
        return ConfInt(exp(estI-Z*stderrlog), exp(estI+Z*stderrlog), estimate)
    end
    #Method of variance estimates recovery (Donner, Zou, 2012)
    function propRRMOVERCI(x1::Int, n1::Int, x2::Int, n2::Int, alpha::Float64)::ConfInt
        p1       = (x1/n1)
        p2       = (x2/n2)
        estimate = (x1/n1)/(x2/n2)
        Z        = quantile(ZDIST, 1-alpha/2)
        wilci1   = propWilsonCI(x1, n1, alpha)
        wilci2   = propWilsonCI(x2, n2, alpha)

        lower    = (p1*p2-sqrt((p1*p2)^2 - wilci1.lower*wilci2.upper*(2*p1-wilci1.lower)*(2*p2-wilci2.upper)))/(wilci2.upper*(2*p2 - wilci2.upper))
        upper    = (p1*p2+sqrt((p1*p2)^2 - wilci1.upper*wilci2.lower*(2*p1-wilci1.upper)*(2*p2-wilci2.lower)))/(wilci2.lower*(2*p2 - wilci2.lower))
        return ConfInt(lower, upper, estimate)
    end
    #-------------------------------MEANS---------------------------------------

    #Normal
    function meanNormCI(m,s,n,alpha)::ConfInt
        e = quanlile(ZDIST, 1-alpha/2)*s/sqrt(n)
        return ConfInt(m-e, m+e, m)
    end
    #T Distribution
    function meanTdistCI(m,s,n,alpha)::ConfInt
        e = quanlile(TDist(n-1), 1-alpha/2)*s/sqrt(n)
        return ConfInt(m-e, m+e, m)
    end
    #mean diff equal var
    function meanDiffEV(m1::Real, s1::Real, n1::Real, m2::Real, s2::Real, n2::Real, alpha::Real)::ConfInt
        diff   = m1 - m2
        stddev = sqrt(((n1 - 1) * s1 + (n2 - 1) * s2) / (n1 + n2 - 2))
        stderr = stddev * sqrt(1/n1 + 1/n2)
        d      = stderr*quantile(TDist(n1+n2-2), 1-alpha/2)
        return ConfInt(diff-d, diff+d, diff)
    end
    function meanDiffEV(a1::AbstractVector{T}, a2::AbstractVector{S}, alpha::Real)::ConfInt where {T<:Real,S<:Real}
        return meanDiffEV(mean(a1), var(a1), length(a1), mean(a2), var(a2), length(a2), alpha)
    end
    #mean diff unequal var
    #Two sample t-test (unequal variance)
    #Welch-Satterthwaite df
    function meanDiffUV(m1::Real, s1::Real, n1::Real, m2::Real, s2::Real, n2::Real, alpha::Real)::ConfInt
        diff   = m1 - m2
        v      = (s1/n1+s2/n2)^2/(s1^2/n1^2/(n1-1)+s2^2/n2^2/(n2-1))
        stderr = sqrt(s1/n1 + s2/n2)
        d      = stderr*quantile(TDist(v), 1-alpha/2)
        return ConfInt(diff-d, diff+d, diff)
    end
    function meanDiffUV(a1::AbstractVector{T}, a2::AbstractVector{S}, alpha::Real)::ConfInt where {T<:Real,S<:Real}
        return meanDiffUV(mean(a1), var(a1), length(a1), mean(a2), var(a2), length(a2), alpha)
    end
end #end module CI