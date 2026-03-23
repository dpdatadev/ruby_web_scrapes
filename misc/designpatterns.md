The Decorator design pattern allows you to add new behaviors or responsibilities to an object dynamically, without modifying its original structure. It provides a flexible alternative to subclassing for extending functionality.

**Core Idea:**
The pattern involves wrapping the original object (the "component") with one or more "decorator" objects. Each decorator adds a specific piece of functionality before, after, or around calling the wrapped object's method. All components and decorators share a common interface, making them interchangeable.

---

### General Summary of the Decorator Pattern

*   **Purpose:** To attach additional responsibilities to an object dynamically. Decorators provide a flexible alternative to subclassing for extending functionality.
*   **Problem Solved:**
    *   **Subclassing Explosion:** Avoids creating a large number of subclasses to get all combinations of behaviors.
    *   **Static Behavior:** Allows adding or removing responsibilities at runtime.
    *   **Violates Open/Closed Principle:** Avoids modifying existing classes to add new features.
*   **Structure:**
    1.  **Component (Interface/Abstract Class):** Defines the interface for objects that can have responsibilities added to them.
    2.  **Concrete Component:** The original object to which new responsibilities can be attached. It implements the Component interface.
    3.  **Decorator (Abstract Class/Interface):** Implements the Component interface and maintains a reference to a Component object. It typically delegates requests to the wrapped component.
    4.  **Concrete Decorator:** Adds specific responsibilities to the component. It extends the Decorator class and overrides methods to add its own behavior before or after calling the wrapped component's method.

---

### Comparison Across Languages

Let's illustrate the Decorator pattern with a common example: a `Coffee` component that can be decorated with `Milk` and `Sugar`.

#### 1. Go

Go leverages its interface system for the Decorator pattern. The "Component" is an interface, and both concrete components and decorators implement this interface. Decorators typically embed the `Component` interface or hold a reference to it.

**Key Go Features:**
*   **Interfaces:** Fundamental for defining the common contract.
*   **Struct Embedding:** A common way for decorators to "inherit" the interface methods and delegate.

```go
package main

import "fmt"

// 1. Component Interface
type Coffee interface {
	GetCost() float64
	GetDescription() string
}

// 2. Concrete Component
type SimpleCoffee struct{}

func (c *SimpleCoffee) GetCost() float64 {
	return 2.0
}

func (c *SimpleCoffee) GetDescription() string {
	return "Simple Coffee"
}

// 3. Decorator (abstract concept, implemented by concrete decorators)
// In Go, this is implicitly handled by structs that implement Coffee
// and hold a reference to another Coffee.

// 4. Concrete Decorator: Milk
type MilkDecorator struct {
	coffee Coffee // Reference to the wrapped coffee
}

func (m *MilkDecorator) GetCost() float64 {
	return m.coffee.GetCost() + 0.5
}

func (m *MilkDecorator) GetDescription() string {
	return m.coffee.GetDescription() + ", Milk"
}

// 4. Concrete Decorator: Sugar
type SugarDecorator struct {
	coffee Coffee
}

func (s *SugarDecorator) GetCost() float64 {
	return s.coffee.GetCost() + 0.2
}

func (s *SugarDecorator) GetDescription() string {
	return s.coffee.GetDescription() + ", Sugar"
}

func main() {
	myCoffee := &SimpleCoffee{}
	fmt.Printf("Cost: %.2f, Desc: %s\n", myCoffee.GetCost(), myCoffee.GetDescription()) // Cost: 2.00, Desc: Simple Coffee

	milkCoffee := &MilkDecorator{coffee: myCoffee}
	fmt.Printf("Cost: %.2f, Desc: %s\n", milkCoffee.GetCost(), milkCoffee.GetDescription()) // Cost: 2.50, Desc: Simple Coffee, Milk

	sweetMilkCoffee := &SugarDecorator{coffee: milkCoffee} // Decorate the already decorated coffee
	fmt.Printf("Cost: %.2f, Desc: %s\n", sweetMilkCoffee.GetCost(), sweetMilkCoffee.GetDescription()) // Cost: 2.70, Desc: Simple Coffee, Milk, Sugar

	// Order matters for description, but not always for cost
	sugarMilkCoffee := &MilkDecorator{coffee: &SugarDecorator{coffee: myCoffee}}
	fmt.Printf("Cost: %.2f, Desc: %s\n", sugarMilkCoffee.GetCost(), sugarMilkCoffee.GetDescription()) // Cost: 2.70, Desc: Simple Coffee, Sugar, Milk
}
```

#### 2. C#

C# uses interfaces and abstract classes in a very classic implementation of the Decorator pattern, similar to its original definition in the Gang of Four book.

**Key C# Features:**
*   **Interfaces:** Define the `IComponent` contract.
*   **Abstract Classes:** Used for the base `Decorator` to hold the wrapped component and provide default delegation.
*   **Inheritance:** Concrete decorators inherit from the abstract `Decorator`.

```csharp
using System;

// 1. Component Interface
public interface ICoffee
{
    double GetCost();
    string GetDescription();
}

// 2. Concrete Component
public class SimpleCoffee : ICoffee
{
    public double GetCost()
    {
        return 2.0;
    }

    public string GetDescription()
    {
        return "Simple Coffee";
    }
}

// 3. Abstract Decorator
public abstract class CoffeeDecorator : ICoffee
{
    protected ICoffee _decoratedCoffee;

    public CoffeeDecorator(ICoffee coffee)
    {
        _decoratedCoffee = coffee;
    }

    // Default delegation
    public virtual double GetCost()
    {
        return _decoratedCoffee.GetCost();
    }

    public virtual string GetDescription()
    {
        return _decoratedCoffee.GetDescription();
    }
}

// 4. Concrete Decorator: Milk
public class MilkDecorator : CoffeeDecorator
{
    public MilkDecorator(ICoffee coffee) : base(coffee) { }

    public override double GetCost()
    {
        return base.GetCost() + 0.5;
    }

    public override string GetDescription()
    {
        return base.GetDescription() + ", Milk";
    }
}

// 4. Concrete Decorator: Sugar
public class SugarDecorator : CoffeeDecorator
{
    public SugarDecorator(ICoffee coffee) : base(coffee) { }

    public override double GetCost()
    {
        return base.GetCost() + 0.2;
    }

    public override string GetDescription()
    {
        return base.GetDescription() + ", Sugar";
    }
}

public class Program
{
    public static void Main(string[] args)
    {
        ICoffee myCoffee = new SimpleCoffee();
        Console.WriteLine($"Cost: {myCoffee.GetCost():C}, Desc: {myCoffee.GetDescription()}"); // Cost: $2.00, Desc: Simple Coffee

        ICoffee milkCoffee = new MilkDecorator(myCoffee);
        Console.WriteLine($"Cost: {milkCoffee.GetCost():C}, Desc: {milkCoffee.GetDescription()}"); // Cost: $2.50, Desc: Simple Coffee, Milk

        ICoffee sweetMilkCoffee = new SugarDecorator(milkCoffee); // Decorate the already decorated coffee
        Console.WriteLine($"Cost: {sweetMilkCoffee.GetCost():C}, Desc: {sweetMilkCoffee.GetDescription()}"); // Cost: $2.70, Desc: Simple Coffee, Milk, Sugar

        ICoffee sugarMilkCoffee = new MilkDecorator(new SugarDecorator(myCoffee));
        Console.WriteLine($"Cost: {sugarMilkCoffee.GetCost():C}, Desc: {sugarMilkCoffee.GetDescription()}"); // Cost: $2.70, Desc: Simple Coffee, Sugar, Milk
    }
}
```

#### 3. Ruby

Ruby's dynamic nature and duck typing make implementing the Decorator pattern quite straightforward. There's no explicit interface needed; any object responding to the required methods can act as a component or decorator. Delegation is often handled explicitly.

**Key Ruby Features:**
*   **Duck Typing:** No explicit interfaces required; objects just need to respond to the same messages.
*   **`method_missing` (optional):** Can be used for implicit delegation, though explicit delegation is often clearer for this pattern.
*   **`super`:** Used to call the decorated object's method.

```ruby
# 1. Component (implicit interface via duck typing)

# 2. Concrete Component
class SimpleCoffee
  def get_cost
    2.0
  end

  def get_description
    "Simple Coffee"
  end
end

# 3. Decorator (abstract concept)
# In Ruby, this is typically a base class that holds the wrapped object
# and delegates to it.
class CoffeeDecorator
  def initialize(coffee)
    @decorated_coffee = coffee
  end

  # Delegate methods to the wrapped object by default
  def get_cost
    @decorated_coffee.get_cost
  end

  def get_description
    @decorated_coffee.get_description
  end
end

# 4. Concrete Decorator: Milk
class MilkDecorator < CoffeeDecorator
  def get_cost
    super + 0.5
  end

  def get_description
    super + ", Milk"
  end
end

# 4. Concrete Decorator: Sugar
class SugarDecorator < CoffeeDecorator
  def get_cost
    super + 0.2
  end

  def get_description
    super + ", Sugar"
  end
end

my_coffee = SimpleCoffee.new
puts "Cost: #{my_coffee.get_cost}, Desc: #{my_coffee.get_description}" # Cost: 2.0, Desc: Simple Coffee

milk_coffee = MilkDecorator.new(my_coffee)
puts "Cost: #{milk_coffee.get_cost}, Desc: #{milk_coffee.get_description}" # Cost: 2.5, Desc: Simple Coffee, Milk

sweet_milk_coffee = SugarDecorator.new(milk_coffee) # Decorate the already decorated coffee
puts "Cost: #{sweet_milk_coffee.get_cost}, Desc: #{sweet_milk_coffee.get_description}" # Cost: 2.7, Desc: Simple Coffee, Milk, Sugar

sugar_milk_coffee = MilkDecorator.new(SugarDecorator.new(my_coffee))
puts "Cost: #{sugar_milk_coffee.get_cost}, Desc: #{sugar_milk_coffee.get_description}" # Cost: 2.7, Desc: Simple Coffee, Sugar, Milk
```

#### 4. Python

Python offers multiple ways to implement the Decorator pattern, benefiting from its dynamic nature and first-class functions. It's common to see both class-based decorators (for general object decoration) and function-based decorators (using the `@` syntax for functions/methods).

**Key Python Features:**
*   **Duck Typing:** Similar to Ruby, no explicit interfaces are needed.
*   **`__call__` method:** Allows an object to be called like a function, useful for function decorators.
*   **`@decorator` syntax:** Syntactic sugar for applying decorators to functions or methods.
*   **Classes for object decoration:** Standard class-based approach for wrapping objects.

---

**Python Example 1: Class-based Decorator (for general object decoration)**
This is analogous to the Go/C#/Ruby examples, wrapping an object.

```python
# 1. Component (implicit interface via duck typing)

# 2. Concrete Component
class SimpleCoffee:
    def get_cost(self):
        return 2.0

    def get_description(self):
        return "Simple Coffee"

# 3. Decorator (abstract concept)
class CoffeeDecorator:
    def __init__(self, coffee):
        self._decorated_coffee = coffee

    def get_cost(self):
        return self._decorated_coffee.get_cost()

    def get_description(self):
        return self._decorated_coffee.get_description()

# 4. Concrete Decorator: Milk
class MilkDecorator(CoffeeDecorator):
    def get_cost(self):
        return super().get_cost() + 0.5

    def get_description(self):
        return super().get_description() + ", Milk"

# 4. Concrete Decorator: Sugar
class SugarDecorator(CoffeeDecorator):
    def get_cost(self):
        return super().get_cost() + 0.2

    def get_description(self):
        return super().get_description() + ", Sugar"

my_coffee = SimpleCoffee()
print(f"Cost: {my_coffee.get_cost()}, Desc: {my_coffee.get_description()}") # Cost: 2.0, Desc: Simple Coffee

milk_coffee = MilkDecorator(my_coffee)
print(f"Cost: {milk_coffee.get_cost()}, Desc: {milk_coffee.get_description()}") # Cost: 2.5, Desc: Simple Coffee, Milk

sweet_milk_coffee = SugarDecorator(milk_coffee) # Decorate the already decorated coffee
print(f"Cost: {sweet_milk_coffee.get_cost()}, Desc: {sweet_milk_coffee.get_description()}") # Cost: 2.7, Desc: Simple Coffee, Milk, Sugar

sugar_milk_coffee = MilkDecorator(SugarDecorator(my_coffee))
print(f"Cost: {sugar_milk_coffee.get_cost()}, Desc: {sugar_milk_coffee.get_description()}") # Cost: 2.7, Desc: Simple Coffee, Sugar, Milk
```

---

**Python Example 2: Function-based Decorator (using `@` syntax for methods/functions)**
This is a very common and idiomatic use of decorators in Python, primarily for adding behavior to functions or methods.

```python
import functools

# A simple logger decorator
def log_execution(func):
    @functools.wraps(func) # Preserves the original function's metadata
    def wrapper(*args, **kwargs):
        print(f"Calling {func.__name__} with args: {args}, kwargs: {kwargs}")
        result = func(*args, **kwargs)
        print(f"{func.__name__} returned: {result}")
        return result
    return wrapper

# A simple timer decorator
def time_execution(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        import time
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print(f"{func.__name__} took {end_time - start_time:.4f} seconds")
        return result
    return wrapper

class Calculator:
    @log_execution
    @time_execution # Decorators are applied from bottom-up (time_execution first, then log_execution wraps it)
    def add(self, a, b):
        return a + b

    @time_execution
    def multiply(self, a, b):
        import time
        time.sleep(0.1) # Simulate some work
        return a * b

calc = Calculator()
print("\n--- Calling add ---")
result_add = calc.add(5, 3)
print(f"Add result: {result_add}")

print("\n--- Calling multiply ---")
result_multiply = calc.multiply(4, 6)
print(f"Multiply result: {result_multiply}")
```
In the function-based example, `@log_execution` is syntactic sugar for `add = log_execution(add)`. When multiple decorators are stacked, they are applied from the bottom up: `add = log_execution(time_execution(add))`.

---

### Key Takeaways from the Comparison:

*   **Go & C#:** Tend to follow the classic GoF (Gang of Four) pattern structure more strictly, relying on explicit interfaces (Go) or interfaces/abstract classes (C#) to define the `Component` contract and manage delegation. This provides strong type safety.
*   **Ruby & Python:** Leverage their dynamic nature and duck typing. Explicit interfaces are not required, making the implementation more flexible and often more concise.
    *   **Ruby:** Often uses explicit delegation and `super` to extend behavior.
    *   **Python:** Offers both class-based object decoration (similar to other languages) and a highly idiomatic function-based decorator syntax (`@`) which is widely used for modifying function/method behavior.

In essence, while the core principle of wrapping an object to add functionality remains the same across all languages, the specific syntactic and structural tools available in each language lead to slightly different, yet equally valid, implementations of the Decorator pattern.
