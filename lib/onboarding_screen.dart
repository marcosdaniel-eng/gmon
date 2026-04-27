import 'package:flutter/material.dart';
import 'package:gmon/Monitor_menu.dart';
import 'package:gmon/container_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'home_page.dart';
import 'main.dart';
class MyOnboarding extends StatefulWidget {
  const MyOnboarding({super.key});

  @override
  State<MyOnboarding> createState() => _MyOnboardingState();
}

class _MyOnboardingState extends State<MyOnboarding> {
  final controller = PageController();
  bool isLastPage  = false;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: controller,
          onPageChanged: (index){
            setState(() {
              isLastPage = index ==2;
            });
          },
          children: [
            //Primer slider
           buildImageContainer(
               Colors.white,
               '¿Qué es un monitor?',
               'Un monitor en la Escuela Miravalles '
                   'es la persona que supervisa, registra la asistencia y cuida el orden y la seguridad de los alumnos, '
                   'pero su labor va más allá:  Es alguien que acompaña, motiva y contribuye a que cada día escolar '
                   'sea un espacio de crecimiento y bienestar para todos.',
               'assets/familia.png'),
            // Segundo Slider sin buldImageContainer
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Image.asset('assets/5razones.png', width: 250),
                  const SizedBox(height: 40),

                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Aquí tienes 5 razones para ser un gran monitor:',
                        style: TextStyle(
                          color: Color(0xFF093E6A),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        item('Compromiso', 'estar presente para servir y apoyar a la comunidad escolar.'),
                        item('Guía', 'orientar a los alumnos para que sigan el camino correcto.'),
                        item('Apoyo', 'brindar ayuda cuando se necesita.'),
                        item('Inspiración', 'motivar a los estudiantes a superarse cada día.'),
                        item('Confianza', 'crear un ambiente seguro, positivo y cercano.'),
                      ],
                    ),
                  ),
                  ),
               ],
              ),
            ),

            // Tercer slider
            buildImageContainer(
                Colors.white,
                'Acuerdos para ser un gran monitor',
                'Yo, como monitor de la Escuela Miravalles, me comprometo a:\n'
                '1.- Cumplir con responsabilidad mis funciones de supervisión y apoyo.\n'
                '2.- Tratar a todos los alumnos con respeto, justicia y empatía.\n'
                'Entiendo que mi labor es fundamental para el buen funcionamiento de la comunidad escolar y acepto este compromiso con orgullo y responsabilidad.',
                'assets/acuerdo.png'),
          ],
        ),
      ),

      bottomSheet:isLastPage
          ? Padding(
          padding: const EdgeInsetsGeometry.all(10.0),
          child:TextButton(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
              backgroundColor:Color(0xFF093E6A),
              minimumSize: const Size.fromHeight(70)),
          onPressed: ()async{

            final prefs = await SharedPreferences.getInstance();
            prefs.setBool('showHome',true);

             Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=> const HomePage()));
          }, 
          child: const Text("De acuerdo", style: TextStyle(fontSize: 24, color: Colors.white),
          )),
          )
          :Container(
        padding:const EdgeInsets.symmetric(
          horizontal: 40,
        ),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //Boton Saltar
            TextButton(
                onPressed: (){},
                child:const Text("Saltar",style: TextStyle(fontSize: 18),)),

            //Slider botones

            //Indicador de slider
            Center(child: SmoothPageIndicator(
                effect: WormEffect(
                  spacing: 15,
                  dotColor: Color(0xb6093e6a),
                  activeDotColor: Color(0xFF093e6a),
                ),
                    onDotClicked: (index) {
                      controller.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut);
                    },
                    controller: controller, count: 3),
            ),
            //Boton Siguiente
            TextButton(
                onPressed: (){
                  controller.nextPage(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut);
                  },
                child:const Text("Siguiente",style: TextStyle(fontSize: 18),)),
          ],
        ),
      ),
    );
  }
}

// Metodo de segundo slider
Widget item(String titulo, String texto) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 15),
        children: [
          TextSpan(
            text: '• $titulo: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: texto),
        ],
      ),
    ),
  );
}