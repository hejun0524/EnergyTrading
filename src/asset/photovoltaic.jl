function _generate_solar_energy(panel::SolarPanel, solar_rate::Float64)
    # max_prod = panel.max_rate * panel.efficiency / 60
    max_prod = panel.max_rate / 60
    return max_prod * solar_rate
end
