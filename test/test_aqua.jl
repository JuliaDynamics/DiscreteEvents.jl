using DiscreteEvents
using Aqua

Aqua.test_all(DiscreteEvents;
    ambiguities = false
)
Aqua.test_ambiguities(DiscreteEvents)