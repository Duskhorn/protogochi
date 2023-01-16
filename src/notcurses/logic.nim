import std/random

type 
    Lifespan = range[0..80]
    Values = range[0..100]
    Multiplier = float
    
    Duration = object
        hours: range[0..23]
        minutes: range[0..59]

    
    Levels[T] = object 
        health, hunger, happiness, tiredness: T
    
    Activity = object
        name: string
        rate: Multiplier
        action: Action
        time: Duration
    
    Action = enum
        Chilling
        Sleeping
        Playing
        Eating

    Protogochi* = object
        name: string
        lifespan, age: Lifespan
        moods: Levels[Values]
        multipliers: Levels[Multiplier]

proc initProtogochi*(name: string): Protogochi =
    randomize()
    result.name = name
    
    result.lifespan = rand(0..(high(Lifespan)-15)) + 15
    result.age = 1

    result.moods.happiness = high(Values)
    result.moods.health = high(Values)
    result.moods.hunger = high(Values)
    result.moods.tiredness = high(Values)

    result.multipliers = Levels[Multiplier](
        health: rand(0.1 .. 1.75),
        hunger: rand(0.1 .. 1.75),
        happiness: rand(0.1 .. 1.75),
        tiredness: rand(0.1 .. 1.75)
    )

## TODO: year cycle: level up, "egg, child, teen, adult", ecc
##  the proot levels up; based on age multipliers are different?
## TODO: Activities: play, eat, sleep, clean...
##  based on age, duration, a current mood (different from the `moods`, like happy, sad, angry...)