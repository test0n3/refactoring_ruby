#books #books2023 #refactoring #ruby
date: 2023-09-25

## Capítulo 1: Refactorización, el primer ejemplo
**Punto de partida**
Ejemplo, programa para calcular e imprimir un comprobante para clientes de una tienda de alquiler de videos.

Input:
- videos que alquila el cliente
- duración del préstamo

requerimientos, información:
- calcular cargos dependiendo de la duración del préstamo y el tipo de video
- 3 tipos de video: REGULAR, CHILDRENS, NEW_RELEASES
- calcular puntos de cliente frecuente

```ruby
class Movie
  REGULAR = 0
  NEW_RELEASE = 1
  CHILDRENS = 2 

  attr_reader :title
  attr_accessor :price_code

  def initialize(title, price_code)
    @title = title
    @price_code = price_code
  end
end
```

```ruby
class Rental
  attr_reader :movie, :days_rented
  
  def initialize(movie, days_rented)
    @movie = movie
    @days_rented = days_rented
  end
end
``` 

```ruby
class Customer
  attr_reader :name, :rentals

  def initialize(name)
    @name = name
    @rentals = []
  end

  def add_rental(arg)
    @rentals << arg
  end

  def statement
    total_amount = 0
    frequent_renter_points = 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      this_amount = 0
      # determine amounts for each line
      case element.movie.price_code
      when Movie::REGULAR
        this_amount += 2
        this_amount += (element.days_rented - 2) * 1.5 if element.days_rented > 2
      when Movie::NEW_RELEASE
        this_amount += element.days_rented * 3
      when Movie::CHILDRENS
        this_amount += 1.5
        this_amount += (element.days_rented - 3) * 1.5 if element.days_rented > 3
      end
      # add frequent renter points
      frequent_renter_points += 1
      # add bonus for a two day new release rental
      frequent_renter_points += 1 if element.movie.price_code == Movie::NEW_RELEASE && element.days_rented > 1
      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + this_amount.to_s + "\n"
      total_amount += this_amount
    end
    # add footer lines
    result += "Amount owed is #{total_amount}\n"
    result += "You earned #{frequent_renter_points} frequent renter points"
    result
  end
end
```

> Un programa rápido y simple no es malo, pero si es parte de un sistema más complejo, entonces es más problemático.

> Al interprete no le importa si el código es feo o limpio. Pero si hay que cambiar el programa, entonces las personas se involucrarán y a ellas si les importa. 

> Un sistema mal diseñado es difícil de cambiar, entonces hay una alta probabilidad de que se cometan errores y se introduzcan bugs.

*Git: refactoring:initial state*

**Nuevos requerimientos**
- Imprimir comprobante en HTML.
- Cambiar la clasificación de películas, pero no ha decidido aún que cambios hacer.

**Problemas con los nuevos requerimientos**
- Con el código como está es difícil poder hacer cambios y no se puede reusar. Se puede hacer un nuevo método, copiando el método `statement` a `html_statement`, pero si hay un nuevo requerimiento entonces habría dos lugares donde se requieren cambios.
- Los cambios en la clasificación de películas cambiarían la forma como se realizan los cálculos. Debido a esta incertidumbre es posible que la duración de estos cambios sea limitada y se tenga que hacer cambios en el corto plazo.

> Si al añadir una nueva característica a un programa, y el código no está estructurado de forma conveniente, primero refactorizar el programa para facilitar añadir la nueva característica.

**El primer paso de refactorizado**
Construir una sólida colección de tests para evitar que se introduzcan bugs. La ventaja de usar librerías/frameworks para pruebas es que hay un resultado final sobre todas la pruebas, presentes, correctas, no pasadas y errores.

**Descomponiendo y redistribuyendo el método *statement***
Divide y vencerás, usar pequeñas piezas las hace más manejables: fáciles de trabajar y de mover.
El objetivo es facilitar la escritura del método para el comprobante HTML con menos duplicación de código.
Se aplicará el método de extracción sobre la sentencia *case*. Pero antes de usar la refactorización, hay que saber como hacerlo de manera segura:
1. Ver si en el fragmento elegido hay variables locales en su alcance respecto al método al que pertenece; variables locales y parámetros.

*Git: refactoring: amount_for*

**Antes**
```ruby
def statement
  total_amount = 0
  frequent_renter_points = 0
  result = "Rental Record for #{@name}\n"
  @rentals.each do |element|
    this_amount = 0  

    # determine amounts for each line
    case element.movie.price_code
    when Movie::REGULAR
      this_amount += 2
      this_amount += (element.days_rented - 2) * 1.5 if element.days_rented > 2
    when Movie::NEW_RELEASE
      this_amount += element.days_rented * 3
    when Movie::CHILDRENS
      this_amount += 1.5
      this_amount += (element.days_rented - 3) * 1.5 if element.days_rented > 3
    end

    # add frequent renter points
    frequent_renter_points += 1
    # add bonus for a two day new release rental
    frequent_renter_points += 1 if element.movie.price_code == Movie::NEW_RELEASE && element.days_rented > 1

    # show figures for this rental
    result += "\t" + element.movie.title + "\t" + this_amount.to_s + "\n"
    total_amount += this_amount
  end
  # add footer lines
  result += "Amount owed is #{total_amount}\n"
  result += "You earned #{frequent_renter_points} frequent renter points"
  result
end
```

**Después**
```ruby
def statement
  total_amount = 0
  frequent_renter_points = 0
  result = "Rental Record for #{@name}\n"
  @rentals.each do |element|
    this_amount = amount_for(element)
  
    # add frequent renter points
    frequent_renter_points += 1
    # add bonus for a two day new release rental
    frequent_renter_points += 1 if element.movie.price_code == Movie::NEW_RELEASE && element.days_rented > 1

    # show figures for this rental
    result += "\t" + element.movie.title + "\t" + this_amount.to_s + "\n"
    total_amount += this_amount
  end
  # add footer lines
  result += "Amount owed is #{total_amount}\n"
  result += "You earned #{frequent_renter_points} frequent renter points"
  result
end

def amount_for(element)
  this_amount = 0
  case element.movie.price_code
  when Movie::REGULAR
    this_amount += 2
    this_amount += (element.days_rented - 2) * 1.5 if element.days_rented > 2
  when Movie::NEW_RELEASE
    this_amount += element.days_rented * 3
  when Movie::CHILDRENS
    this_amount += 1.5
    this_amount += (element.days_rented - 3) * 1.5 if element.days_rented > 3
  end
  this_amount
end
```

Hacer pruebas frecuentemente es vital para rastrear las causas, lo que no es posible si es que se han acumulado varios cambios.

Habiendo separado el método original en pedazos, podemos usar nombres de variables más apropiados:

> El buen código debe comunicar que esta haciendo claramente y el nombre de las variables son llave para un código claro

*Git: refactoring: renaming*

Antes:
```ruby
def amount_for(element)
  this_amount = 0
  case element.movie.price_code
  when Movie::REGULAR
    this_amount += 2
    this_amount += (element.days_rented - 2) * 1.5 if element.days_rented > 2
  when Movie::NEW_RELEASE
    this_amount += element.days_rented * 3
  when Movie::CHILDRENS
    this_amount += 1.5
    this_amount += (element.days_rented - 3) * 1.5 if element.days_rented > 3
  end
  this_amount
end
```

Después:
```ruby
def amount_for(rental)
  result = 0
  case rental.movie.price_code
  when Movie::REGULAR
    result += 2
    result += (rental.days_rented - 2) * 1.5 if rental.days_rented > 2
  when Movie::NEW_RELEASE
    result += rental.days_rented * 3
  when Movie::CHILDRENS
    result += 1.5
    result += (rental.days_rented - 3) * 1.5 if rental.days_rented > 3
  end
  result
end
```

> Cualquier tonto puede escribir código que una computadora puede entender. Buenos programadores escriben código que los humanos pueden entender.

**Moviendo el cálculo de la cantidad**
El método *amount_for* usa información de **Rental** pero no usa información de **Customer**. Esto nos hace pensar que está en el objeto equivocado. Los métodos deberían estar en el objeto que tiene los datos.
Se usará el método Mover para trasladar el método *amount_for* a la clase **Rental**. Se copia el código y se ajusta para sus nuevas funciones: remover los parámetros y cambiar el nombre  del método. 

*Git: refactoring: moving*

```ruby
class Rental
  attr_reader :movie, :days_rented
  
  def initialize(movie, days_rented)
    @movie = movie
    @days_rented = days_rented
  end
  
  def charge
    result = 0
    case movie.price_code
    when Movie::REGULAR
      result += 2
      result += (days_rented - 2) * 1.5 if days_rented > 2
    when Movie::NEW_RELEASE
      result += days_rented * 3
    when Movie::CHILDRENS
      result += 1.5
      result += (days_rented - 3) * 1.5 if days_rented > 3
    end
    result
  end
end
```

Y cambiar la invocación para el nuevo procedimiento:
```ruby
class Customer
  ...
  def amount_for(rental)
    rental.charge
  end
end
```

Esto para hacer las pruebas respectivas con el nuevo método. Pasado esto se puede usar la invocación al nuevo método en la clase **Customer**.

*Git: refactoring: replacing1*

```ruby
class Customer
  ...
  def statement
    total_amount = 0
    frequent_renter_points = 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
	  this_amount = element.charge
      # add frequent renter points
      frequent_renter_points += 1
      # add bonus for a two day new release rental
      frequent_renter_points += 1 if element.movie.price_code == Movie::NEW_RELEASE && element.days_rented > 1

      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + this_amount.to_s + "\n"
      total_amount += this_amount
    end
    # add footer lines
    result += "Amount owed is #{total_amount}\n"
    result += "You earned #{frequent_renter_points} frequent renter points"
    result
  end
end
```

Y luego eliminar la variable temporal
```ruby
class Customer
  ...
  def statement
    total_amount = 0
    frequent_renter_points = 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      # add frequent renter points
      frequent_renter_points += 1
      # add bonus for a two day new release rental
      frequent_renter_points += 1 if element.movie.price_code == Movie::NEW_RELEASE && element.days_rented > 1

      # show firgures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
      total_amount += element.charge
    end
    # add footer lines
    result += "Amount owed is #{total_amount}\n"
    result += "You earned #{frequent_renter_points} frequent renter points"
    result
  end
end
```

*Git: refactoring: replacing2*

Puede parecer preocupante la eliminación de la variable temporal por razones de rendimiento. Se estaría invocando al método *charge* dos veces, pero mientras se está refactorizando, el objetivo debe ser la claridad para después enfocarse específicamente en rendimiento.

El riesgo es estar seguro que el método *charge* es idempotente, esto es que sin importar el número de veces que se invoque sobre un valor, siempre devolverá el mismo valor. 
Por tanto un método de consulta no tiene efectos secundarios.

Las variables temporales son problemáticas por que hacen que varios parámetros estén circulando cuando no es necesario. Al eliminarlos, nos enfocamos en lo que quiere hacer el código.

**Extrayendo puntos de cliente frecuente**
Primero usamos el método de extracción en el código para calcular los puntos de cliente frecuente, lo movemos al objeto del que depende, **Rental**, adaptamos apropiadamente el método, e invocándolo apropiadamente en el objeto donde se le usa, **Customer**.

*git: refactoring:frequent renter points*

```ruby
class Customer
  ...
  def statement
    total_amount = 0
    frequent_renter_points = 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      frequent_renter_points += element.frequent_renter_points

      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
      total_amount += element.charge
    end
    # add footer lines
    result += "Amount owed is #{total_amount}\n"
    result += "You earned #{frequent_renter_points} frequent renter points"
    result
  end
end

class Rental
  ...
  def frequent_renter_points
    (movie.price_code == Movie::NEW_RELEASE && days_rented > 1) ? 2 : 1
  end
end
```

**Removiendo temporales**
Hay dos variables temporales usadas para contener los totales de las rentas del cliente. Es mejor usar consultas y variables temporales para *total_amount* y *frequent_renter_points*.

Las consultas son accesibles para cualquier método en la clase y muestra un diseño más limpio sin métodos largos y complejos.

*Git: refactoring: remove temporal*

```ruby
class Customer
  ...
  def statement
    frequent_renter_points = 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      frequent_renter_points += element.frequent_renter_points

      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
    end
    # add footer lines
    result += "Amount owed is #{total_charge}\n"
    result += "You earned #{frequent_renter_points} frequent renter points"
    result
  end

  private
  
  def total_charge
    result = 0
    @rentals.each do |element|
      result += element.charge
    end
    result
  end
end
```

*Git: refactoring: improve helpers*

```ruby
class Customer
  ...
  def statement
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
    end
    # add footer lines
    result += "Amount owed is #{total_charge}\n"
    result += "You earned #{total_frequent_renter_points} frequent renter points"
    result
  end

  private
  
  def total_charge
    @rentals.inject(0) { |sum, rental| sum + rental.charge }
  end

  def total_frequent_renter_points
    @rentals.inject(0) { |sum, rental| sum + rental.frequent_renter_points }
  end
end
```

**Comenzando con el primer requerimiento**
Al haber sacado los cálculos se puede crear el método *html_statement* y reusar el código del método *statement*.

*Git: refactoring: html_statement*

```ruby
class Customer
  def html_statement
    result = "<h1>Rental Record for #{@name}</h1><p>\n"
    @rentals.each do |element|
      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
    end
    # add footer lines
    result += "Amount owed is #{total_charge}\n"
    result += "You earned #{total_frequent_renter_points} frequent renter points"
    result
  end
end
```

**Reemplazando la lógica condicional en price_code con polimorfismo**
Observemos el condicional *case* de la clase **Rental**. Es una mala idea usar un *case* basado en un atributo de otro objeto. Si es que hay que usar un *case*, debe usar los datos propios del objeto.

Tenemos que mover el método a *charge* a **Movie**. Para que funcione, se debe proporcionar el tamaño de *rental*. Se usa los tipos de datos: el tamaño de *rental* y el tipo de *película*.

*Git: refactoring: new types*

```ruby
class Rental
  ...  
  def charge
    result = 0
    case movie.price_code
    when Movie::REGULAR
      result += 2
      result += (days_rented - 2) * 1.5 if days_rented > 2
    when Movie::NEW_RELEASE
      result += days_rented * 3
    when Movie::CHILDRENS
      result += 1.5
      result += (days_rented - 3) * 1.5 if days_rented > 3
    end
    result
  end
end
```

Porqué pasar rental en lugar de movie? Por que los cambios que se requieren se refiere a Movie, los tipos de movie. Si cambian los tipos de **Movie**, se requiere que haya el menor efecto.

Se hace lo mismo para el cálculo de puntos por cliente frecuente.

```ruby
class Rental
  ...  
  def charge
    movie.charge(days_rented)
  end

  def frequent_renter_points
    movie.frequent_renter_points(days_rented)
  end
end

class Movie
  ...
  def charge(days_rented)
    result = 0
    case price_code
    when REGULAR
      result += 2
      result += (days_rented - 2) * 1.5 if days_rented > 2
    when NEW_RELEASE
      result += days_rented * 3
    when CHILDRENS
      result += 1.5
      result += (days_rented - 3) * 1.5 if days_rented > 3
    end
    result
  end

  def frequent_renter_points(days_rented)
    (price_code == NEW_RELEASE && days_rented > 1) ? 2 : 1
  end
end
```

**Al fin herencia**
Tenemos varios tipos de películas que pueden responder de forma diferente a la misma pregunta: un trabajo para subclases. Hay 3 subclases de película, cada una tiene su propia versión de *charge*. Esto permitiría reemplazar el condicional *case* con polimorfismo, pero no funcionaría por que una película puede cambiar durante su tiempo de vida. La otra opción es reemplazar el condicional con el patrón de estados. 
En este momento la elección del patrón(y nombre) refleja como se quiere pensar sobre la estructura. Lo relevante es que si se decide por una estrategia en lugar de estados, se refactorizará cambiando los nombres.

La refactorización a usar es reemplazar el código tipo con estado/estrategia.
El primer paso es usar `Self Encapsule Field` con el código tipo para asegurar que todos los usos del código tipo pasen por métodos getter y setter. 

Utilizamos un setter personalizado que se invoca desde el constructor.
Luego se crean las clases nuevas que añaden el comportamiento código tipo.

*Git: refactoring: inheritance1*

```ruby
class Movie
  attr_reader :title, :price_code

  def price_code=(value)
    @price_code = value
    @price = case price_code
	         when REGULAR
               RegularPrice.new
             when NEW_RELEASE
               NewRelease.new
             when CHILDRENS
               ChildrensPrice.new
             end
  end

  def initialize(title, price_code)
    @title, self.price_code = title, price_code
  end
end

class RegularPrice
end

class NewReleasePrice
end

class ChildrensPrice
end
```

Lo irónico es que se prometió eliminar la condicional case, pero este será el único caso pero puede que sea eliminado después.

Luego se selecciona uno de los métodos que necesitan un comportamiento polimórfico, y se pasa a adaptarlo en el método *charge* de las clases creadas.

```ruby
class Movie
  ...
  def charge(days_rented)
    # result = 0
    case price_code
    when REGULAR
      # result += 2
      # result += (days_rented - 2) * 1.5 if days_rented > 2
      return @price.charge(days_rented)
    when NEW_RELEASE
      # result += days_rented * 3
      return @price.charge(days_rented)
    when CHILDRENS
      # result += 1.5
      # result += (days_rented - 3) * 1.5 if days_rented > 3
      return @price.charge(days_rented)
    end
    # result
  end
end

class RegularPrice
  def charge(days_rented)
    result = 2
    result += (days_rented - 2) * 1.5 if days_rented > 2
    result
  end
end

class NewReleasePrice
  def charge(days_rented)
    days_rented * 3
  end
end

class ChildrensPrice
  def charge(days_rented)
    result = 1.5
    result += (days_rented - 3) * 1.5 if days_rented > 3
    result
  end
end
```

*Git: refactoring:inheritance2*

Finalmente **Movie.charge** se convertirá en un delegador:
```ruby
class Movie
  def charge(days_rented)
    @price.charge(days_rented)
  end
end
```

Luego seguimos con *frequent_renter_points*:
```ruby
class Movie
  def frequent_renter_points(days_rented)
    (price_code == NEW_RELEASE && days_rented > 1) ? 2 : 1
  end
end
```

Se desea que *frequent_renter_points* sea el mismo para **ChildrensPrice** y **RegularPrice** y diferente para **NewReleasePrice**. Extraemos el procedimiento a un módulo que se incluye en **RegularPrice** y **ChildrensPrice**.

```ruby
class Movie
  def frequent_renter_points(days_rented)
    @price.frequent_renter_points(days_rented)
  end
end

class RegularPrice
  include DefaultPrice
  ...
end

class NewReleasePrice
  def frequent_renter_points(days_rented)
    days_rented > 1 ? 2 : 1
  end
end

class ChildrensPrice
  include DefaultPrice
  ...
end

module DefaultPrice
  def frequent_renter_points(_days_rented)
    1
  end
end
```

Y con esto *Movie.frequent_renter_points* se vuelve un delegador.

```ruby
class Movie
  def frequent_renter_points(days_rented)
    @price.frequent_renter_points(days_rented)
  end
end
```

Esto es bastante trabajo, pero la ganancia es que si se cambia cualquier comportamiento de precio, añadir nuevos precios o añadir más comportamientos dependientes del precio; el cambio será más sencillo de hacer y el resto de la aplicación no sabe sobre el uso del patrón de estado.

**Resumen:**
Se usan varios procesos de refactorización:
- método de extracción
- método de traslado
- reemplazo de código tipo con patrón State/Strategy

Otro punto relevante es el ritmo de la refactorización: probar, pequeño cambio, probar, pequeño cambio,...

---

Los patrones Strategy y State son muy parecidos, teniendo el mismo origen pero finalidades diferentes.
**Patrón strategy**: encapsular comportamientos intercambiables y usa delegación para decidir cual usar.
**Patrón state**: encapsular comportamientos basados en estados y usa delegación para intercambiar estos.

---