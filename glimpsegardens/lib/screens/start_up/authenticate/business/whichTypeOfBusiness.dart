import 'package:flutter/material.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/businessOrUser.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/mapDropPinPrompt.dart';
import 'package:carousel_slider/carousel_slider.dart';

// ignore: camel_case_types
class whichTypeofBusiness extends StatefulWidget {
  final PassingUser pUser;

  const whichTypeofBusiness({Key key, @required this.pUser}) : super(key: key);

  @override
  _whichTypeofBusiness createState() => _whichTypeofBusiness();
}

// ignore: camel_case_types
class _whichTypeofBusiness extends State<whichTypeofBusiness> {
  // Text field state
  String email = "";
  String password = "";
  String passwordTwo = "";
  String error = "";
  String firstName = "";

  int currentIndex = 0;

  CarouselController buttonCarouselController = CarouselController();

  double opacity = 1.0;
  double littleCircleSize = 6;

  List littleCircles = <Widget>[];

  List order = [0, 1, 2, 3, 4, 5, 6, 11, 7, 8, 9, 10];

  List descriptions = [
    currentLanguage[237],
    currentLanguage[238],
    currentLanguage[239],
    currentLanguage[240],
    currentLanguage[241],
    currentLanguage[242],
    currentLanguage[243],
    currentLanguage[244],
    currentLanguage[245],
    currentLanguage[246],
    currentLanguage[247],
    currentLanguage[248]
  ];

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 12; i++) {
      if (i == 0) {
        littleCircles.add(Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: const BoxDecoration(
            color: buttonsBorders,
            shape: BoxShape.circle,
          ),
        ));
      } else {
        littleCircles.add(Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: const BoxDecoration(
            color: lightTone,
            shape: BoxShape.circle,
          ),
        ));
      }
    }
  }

  resetColors(int index) {
    littleCircles.clear();
    for (int i = 0; i < 12; i++) {
      if (i == index) {
        littleCircles.add(Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: const BoxDecoration(
            color: buttonsBorders,
            shape: BoxShape.circle,
          ),
        ));
      } else {
        littleCircles.add(Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: const BoxDecoration(
            color: lightTone,
            shape: BoxShape.circle,
          ),
        ));
      }
    }
  }

  changeOpacity() {
    setState(() {
      opacity = 0.0;
    });
  }

  onEndOpacity() {
    setState(() {
      opacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Arial'),
        home: Scaffold(
            backgroundColor: fadedOutButtons,
            body: SingleChildScrollView(
                child: Column(children: [
              const SizedBox(height: 25),
              Stack(
                children: [
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Center(
                      child: Text(
                        currentLanguage[122],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14,
                            color: headers,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  Container(
                      alignment: Alignment.centerLeft,
                      child: IconTheme(
                        data: const IconThemeData(color: normalText),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ))
                ],
              ),
              Center(
                  child: Container(
                color: Colors.white,
                width: size.width / 1.2,
                height: size.height / 1.2,
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Center(
                      child: Text(currentLanguage[9],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, color: buttonsBorders)),
                    ),
                    const SizedBox(height: 30),
                    Stack(children: [
                      CarouselSlider(
                        carouselController: buttonCarouselController,
                        options: CarouselOptions(
                            enableInfiniteScroll: false,
                            autoPlay: false,
                            onPageChanged: (index, reason) {
                              setState(() {
                                currentIndex = order[index];
                              });
                              resetColors(index);
                            }),
                        items: order.map((i) {
                          return Builder(
                            builder: (BuildContext context) {
                              // ignore: avoid_unnecessary_containers
                              return Container(
                                  child: Column(children: [
                                // ignore: sized_box_for_whitespace
                                Container(
                                  child: iconImages[i],
                                  width: size.width / 2.5,
                                ),
                              ]));
                            },
                          );
                        }).toList(),
                      ),
                      Container(
                        height: (size.width / 2.5) + 40,
                        width: size.width,
                        alignment: Alignment.bottomCenter,
                        // ignore: sized_box_for_whitespace
                        child: Container(
                          height: 40,
                          child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: littleCircles.length,
                              itemBuilder: (BuildContext context, int index) {
                                return index == littleCircles.length - 1
                                    ? Row(children: [
                                        littleCircles[index],
                                      ])
                                    : Row(children: [
                                        littleCircles[index],
                                        const SizedBox(width: 10)
                                      ]);
                              }),
                        ),
                      )
                    ]),
                    AnimatedOpacity(
                      onEnd: onEndOpacity,
                      duration: const Duration(seconds: 1),
                      opacity: opacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Text(
                          /*ConstantsClass.isInEnglish
                              ? englishDescriptions[currentIndex]
                              : spanishDescriptions[currentIndex],
                              */
                          "" + descriptions[currentIndex],
                          textAlign: TextAlign.left,
                          style:
                              const TextStyle(fontSize: 16, color: normalText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    TextButton(
                        style: loginPageButtonStyle,
                        child: Text(currentLanguage[10],
                            style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => mapDropPinprompt(
                                  pUser: widget.pUser,
                                  businessType: currentIndex),
                            ),
                          );
                        }),
                  ],
                ),
              )),
            ]))));
  }
}
