# Pre-response checklist

- [ ] Does any Model know a View, a Controller or a Unity component?
- [ ] Does any View handle input, call commands or know a service? Does an inner View read the Model? More than 5 serialized fields?
- [ ] Does any Controller change a visual, hold a rule or serialize a reference?
- [ ] Does any event have parameters? Is anything pushed that could be pulled?
- [ ] Is there a `Button`, `Toggle`, `Slider`, `Dropdown`, `onClick` or `Initialize(model)`? A package that isn't installed?
- [ ] Injected fields `internal` with no attribute; everything else `private`?
- [ ] Every file in its folder, source art outside the feature?
- [ ] Lambdas, LINQ, `var`, `?.` on Unity objects, `///` on members, hardcoded text?
- [ ] Could a tool have decided this? Does a Model read time or randomness directly?
- [ ] Everything testable covered, with Model tests first?
- [ ] Model and View on their scope root?
- [ ] Cycles between Models? A Model with serialized fields?
- [ ] Is it the minimum, with no unused abstraction?
- [ ] Did a tool verify compile, analyzers, tests and generation?
