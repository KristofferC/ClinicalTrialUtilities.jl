println(" ---------------------------------- ")
@testset "  PK                    " begin


    #pk = ClinicalTrialUtilities.PK.nca(data; conc = :Concentration, sort=[:Formulation, :Subject])
    #@test pk.result.AUCinf[1] ≈ 1.63205 atol=1E-5
    #@test pk.result.Cmax[1] ≈ 0.4 atol=1E-5
    #@test pk.result.MRTlast[1] ≈ 3.10345 atol=1E-5
    #@test pk.result.Tmax[1] ≈ 3.0 atol=1E-5

    pkds = ClinicalTrialUtilities.pkimport(pkdata, [:Subject, :Formulation]; conc = :Concentration, time = :Time)
    pk   = ClinicalTrialUtilities.nca!(pkds)
    @test pk[1, :AUCinf]  ≈ 1.63205 atol=1E-5
    @test pk[1, :Cmax]    ≈ 0.4 atol=1E-5
    @test pk[1, :MRTlast] ≈ 3.10345 atol=1E-5
    @test pk[1, :Tmax]    ≈ 3.0 atol=1E-5

    pk   = ClinicalTrialUtilities.nca!(pkds; calcm = :logt)
    @test pk[1, :AUClast]  ≈ 1.43851 atol=1E-5
    @test pk[1, :AUMClast] ≈ 4.49504 atol=1E-5
    pk   = ClinicalTrialUtilities.nca!(pkds; calcm = :luld)
    @test pk[1, :AUClast]  ≈ 1.43851 atol=1E-5
    @test pk[1, :AUMClast] ≈ 4.49504 atol=1E-5

    pkds = ClinicalTrialUtilities.pkimport(pkdata[1:7,:], [:Subject, :Formulation]; conc = :Concentration, time = :Time)
    pk   = ClinicalTrialUtilities.nca!(pkds)
    @test pk[1, :AUCinf]  ≈ 1.63205 atol=1E-5
    @test pk[1, :Cmax]    ≈ 0.4 atol=1E-5
    @test pk[1, :MRTlast] ≈ 3.10345 atol=1E-5
    @test pk[1, :Tmax]    ≈ 3.0 atol=1E-5

    pkds = ClinicalTrialUtilities.pkimport(pkdata2, [:Subject, :Formulation]; conc = :Concentration, time = :Time)
    pk   = ClinicalTrialUtilities.nca!(pkds)
    df   = DataFrame(pk; unst = true)
    sort!(df, :Subject)

    #Linear-trapezoidal rule
    #AUC
    @test round.(df[!, :AUClast], sigdigits = 6) == round.([9585.4218
    10112.176
    5396.5498
    9317.8358
    9561.26
    6966.598
    7029.5735
    7110.6745
    8315.0803
    5620.8945], sigdigits = 6)

    #Cmax
    @test df[!, :Cmax] == [190.869
    261.177
    105.345
    208.542
    169.334
    154.648
    153.254
    138.327
    167.347
    125.482]

    #Clast
    @test df[!, :Clast] == [112.846
    85.241
    67.901
    97.625
    110.778
    69.501
    58.051
    74.437
    93.44
    42.191]

    #Adjusted R sq
    @test round.(df[!, :ARsq], digits = 6) == round.([0.71476928
    0.99035145
    0.77630678
    0.83771737
    0.82891994
    0.92517856
    0.96041642
    0.92195356
    0.92130684
    0.86391165], digits = 6)

    #Kel
    @test round.(df[!, :Kel], sigdigits = 6) == round.([0.0033847439
    0.014106315
    0.0032914304
    0.0076953442
    0.0068133279
    0.0076922807
    0.012458956
    0.0089300798
    0.0056458649
    0.017189737], sigdigits = 6)

    @test round.(df[!, :AUCinf], sigdigits = 6) == round.([42925.019
    16154.93
    26026.183
    22004.078
    25820.275
    16001.76
    11688.953
    15446.21
    24865.246
    8075.3242], sigdigits = 6)


    @test df[!, :Tmax] == [1
    1
    1.5
    1
    4
    2.5
    2.5
    4
    3
    2]

    @test round.(df[!, :MRTlast], digits = 6) == round.([34.801023
    29.538786
    34.472406
    33.69408
    32.964438
    32.58076
    31.267574
    33.826053
    33.386807
    27.556657], digits = 6)

    @test round.(df[!, :Clast_pred], sigdigits = 6) == round.([117.30578
    82.53669
    66.931057
    100.76793
    105.29832
    71.939942
    61.172702
    75.604277
    93.761762
    38.810857], sigdigits = 6)



    #glucose2
    pkds = ClinicalTrialUtilities.pkimport(glucose2, [:Subject, :Date]; conc = :glucose, time = :Time)
    pk   = ClinicalTrialUtilities.nca!(pkds)
    df   = DataFrame(pk; unst = true)

end


println(" ---------------------------------- ")
@testset "  PD                    " begin

    #PD
    pdds = ClinicalTrialUtilities.pdimport(pddata; time=:time, resp=:effect, bl = 3.0)
    pd   = ClinicalTrialUtilities.nca!(pdds)
    @test pd[1,:AUCABL]   ≈ 7.38571428571429 atol=1E-5
    @test pd[1,:AUCBBL]   ≈ 8.73571428571429 atol=1E-5
    ClinicalTrialUtilities.setth!(pdds, 1.5)
    pd   = ClinicalTrialUtilities.nca!(pdds)
    @test pd[1,:AUCATH]   ≈ 13.9595238095238 atol=1E-5
    @test pd[1,:AUCBTH]   ≈ 1.80952380952381 atol=1E-5
    @test pd[1,:TABL]     ≈ 3.48095238095238 atol=1E-5
    @test pd[1,:TBBL]     ≈ 5.51904761904762 atol=1E-5
    @test pd[1,:TATH]     ≈ 5.76190476190476 atol=1E-5
    @test pd[1,:TBTH]     ≈ 3.23809523809524 atol=1E-5
    @test pd[1,:AUCBLNET] ≈ -1.35 atol=1E-5
    @test pd[1,:AUCTHNET] ≈ 12.15 atol=1E-5

    pdds = ClinicalTrialUtilities.pdimport(pkdata, [:Formulation, :Subject]; time=:Time, resp=:Concentration, bl=0.2, th=0.3)
    pd   = ClinicalTrialUtilities.nca!(pdds)
    @test pd[2, :AUCDBLTH] ≈ 0.3416666666666665 atol=1E-5
    ClinicalTrialUtilities.setbl!(pdds, 0.3)
    ClinicalTrialUtilities.setth!(pdds, 0.2)
    pd   = ClinicalTrialUtilities.nca!(pdds)
    @test pd[3, :AUCDBLTH] ≈ 0.3428571428571429 atol=1E-5

end