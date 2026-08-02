# Mock data:
# add more for other models
tmp_land = (;
    cCycleDisturbance = (;
        zix_veg_all = (1, 2, 3, 4),
        c_lose_to_zix_vec = ((5,), (6,), (5,), (6,))),
    pools = (;
        cEco = Float32[25.0, 25.0, 25.0, 10.0, 100.0, 250.0, 500.0, 1000.0],
        cVeg = Float32[25.0, 25.0, 25.0, 10.0],
        cLit = Float32[100.0, 250.0],
        cSoil = Float32[500.0, 1000.0],
        cVegRoot = Float32[25.0],
        cVegWood = Float32[25.0],
        cVegLeaf = Float32[25.0],
        cVegReserve = Float32[10.0],
        cLitFast = Float32[100.0],
        cLitSlow = Float32[250.0],
        cSoilSlow = Float32[500.0],
        cSoilOld = Float32[1000.0],
        TWS = Float32[100.0, 100.0, 100.0, 100.0, 1000.0, 0.01, 0.01],
        soilW = Float32[100.0, 100.0, 100.0, 100.0],
        groundW = Float32[1000.0],
        snowW = Float32[0.01],
        surfaceW = Float32[0.01],
        ΔTWS = Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        ΔsoilW = Float32[0.0, 0.0, 0.0, 0.0],
        ΔgroundW = Float32[0.0],
        ΔsnowW = Float32[0.0],
        ΔsurfaceW = Float32[0.0],
        ΔcEco = Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
    constants = (;
        c_taker = (4, 5, 6, 4, 5, 1, 3, 7, 7, 8), # ? we might have a different order for the fireEmissions case!
        c_giver = (1, 1, 2, 3, 3, 4, 4, 5, 6, 7),
        z_zero = 0.0f0,
        o_one = 1.0f0,
        ),
    states = (;
        c_remain = 5.0f0, # do less, so that we don't start at zero, when comparing to cEco[zixVeg]
        frac_tree = 0.5f0,
        ),
    diagnostics = (;
        gpp_f_soilW = 0.5f0, # 1.0f0
        C_to_N_cVeg = [0.25f0, 0.25f0, 0.25f0, 0.25f0],
        c_allocation =[0.25f0, 0.25f0, 0.25f0, 0.25f0],
        auto_respiration_f_airT = 0.5f0,
        c_fVegDieOff = 0.5f0, # 0.5f0,
        c_fire_fba = 0.5f0, #0.5f0,
        c_Fire_cci = [0.0f0, 0.25f0, 0.9f0, 0.25f0, 0.9f0, 0.5f0, 0.9f0, 0.0f0],
        c_Fire_k = [0.65065634f0, 0.30131266f0, 0.65065634f0, 0.65065634f0, 1f0, 1f0, 1f0, 1f0]
        ),
    properties = (;
        ∑w_sat = 0.2f0 # 783.7831f0
        ),
    fluxes = (;
        gpp = 0.5f0
        )
    )

    # constants = (; n_TWS = 7.0f0, n_groundW = 1.0f0, n_snowW = 1.0f0, n_soilW = 4.0f0, n_surfaceW = 1.0f0, z_zero = 0.0f0, o_one = 1.0f0, t_two = 2.0f0, t_three = 3.0f0, c_flow_order = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10), c_taker = (4, 5, 6, 4, 5, 1, 3, 7, 7, 8), c_giver = (1, 1, 2, 3, 3, 4, 4, 5, 6, 7))
