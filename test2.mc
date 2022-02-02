/************************
 * Fichero de prueba nº 1
 
 ************************/

void junio_2021() {
    // Declaraciones
    const a=0, b=100;
    var x52=(a+b*(10-6))/100,y,z; //x52=4
    // Sentencias
    print "Comenzamos simulación \\ junio 2021\n";
    if (a) print "Esto no va bien con a=",a,"\n";
    else if (b-100) print "Esto no va bien con b\n";
         else while (x52) {
            print "Introduce valores de 'y' y 'z' 4 veces\n";
             read y,z;
             print "y=",y,", z=",z,"\n";
             x52 = x52-1;
         }
    print "Termina correctamente","\n";
}
