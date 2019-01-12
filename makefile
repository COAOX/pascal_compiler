cc = g++
flags = -pedantic
objects = emitter.o error.o lexer.o main.o parser.o symbol.o

comp: $(objects)
	$(cc)  $(flags) $(objects) -o comp
lexer.cpp: lexer.l global.hpp
	flex -o lexer.cpp lexer.l
parser.cpp parser.hpp: parser.y
	bison -o parser.cpp -d parser.y
emitter.o: emitter.cpp parser.hpp global.hpp symbol.hpp
	$(cc) $(flags) -c emitter.cpp -o emitter.o
lexer.o: lexer.cpp global.hpp
	$(cc) $(flags) -c lexer.cpp -o lexer.o
error.o: error.cpp global.hpp
	$(cc) $(flags) -c error.cpp -o error.o
main.o: main.cpp global.hpp
	$(cc) $(flags) -c main.cpp -o main.o
parser.o: parser.cpp parser.hpp global.hpp
	$(cc) $(flags) -c parser.cpp -o parser.o
symbol.o: symbol.cpp symbol.hpp global.hpp
	$(cc) $(flags) -c symbol.cpp -o symbol.o

clean:
	rm -f *.o
	rm -f comp
	rm -f lexer.cpp
	rm -f parser.cpp
	rm -f parser.hpp

.PHONY : clean