#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

"""
    register!(clk::Clock, ch::Channel)

Register a channel to a clock. The clock proceeds only to the next 
event if this channel is empty. This allows tasks/actors getting
messages from that channel to complete their cycle before the 
clock proceeds. 
"""
register!(clk::Clock, ch::Channel) = push!(clk.channels, ch)