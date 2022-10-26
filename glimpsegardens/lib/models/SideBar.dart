// ignore_for_file: prefer_initializing_formals, prefer_if_null_operators, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:glimpsegardens/shared/constants.dart';

// ignore: must_be_immutable
class ShelfItem extends StatelessWidget {
  Widget one;
  Widget two;

  ShelfItem(Widget one, Widget two, {Key key}) : super(key: key) {
    this.one = one;
    this.two = two;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: two == null ? MainAxisSize.min : MainAxisSize.max,
      children: [
        one,
        two == null ? Container() : const SizedBox(width: 10),
        two == null ? Container() : two
      ],
    );
  }
}

// ignore: must_be_immutable
class SideBarItem extends StatelessWidget {
  static String selectedName = "All";

  String name;
  String assetName;
  Widget svg;
  String nameEnglish;

  SideBarItem(String name, String img) {
    this.name = name;
    nameEnglish = img;
    assetName = 'assets/drawable/' + img + '.png';

    if (nameEnglish != "All") {
      svg = Image.asset(
        assetName,
        width: 40,
        height: 40,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: GestureDetector(
            onTap: () {
              selectedName = nameEnglish;
              Navigator.pop(context);
            },
            child: Container(
                decoration: const BoxDecoration(
                    color: fadedOutButtons,
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                child: Row(
                    mainAxisAlignment: nameEnglish != 'All'
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      nameEnglish != "All"
                          ? Padding(
                              child: svg,
                              padding: const EdgeInsets.all(6.0),
                            )
                          : const SizedBox(height: 52),
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Arial',
                              color: normalText),
                        ),
                      ),
                      const SizedBox(width: 5)
                    ]))));
  }
}
