import 'package:flutter/material.dart';
import 'package:glimpsegardens/shared/constants.dart';

abstract class ListItem {
  Widget buildTitle(BuildContext context);

  Widget buildSubtitle(BuildContext context);
}

class MessageItem implements ListItem {
  final String sender;
  final String body;
  final String url;
  final String imgurl;
  final int count;
  final bool isVideo;

  MessageItem(
      this.sender, this.body, this.url, this.imgurl, this.count, this.isVideo);

  @override
  Widget buildTitle(BuildContext context) => url == "q"
      ? Text(sender)
      : RichText(
          text: TextSpan(
              style: const TextStyle(
                color: Colors.black,
              ),
              children: <TextSpan>[
                TextSpan(
                    text: count.toString() + ": ",
                    style: TextStyle(color: Colors.black54)),
                TextSpan(text: sender),
              ]),
        );

  @override
  Widget buildSubtitle(BuildContext context) => Text(body);

  Widget buildImage(BuildContext context) => imgurl == null
      ? CircleAvatar(
          backgroundColor: normalText,
        )
      : CircleAvatar(
          backgroundImage: NetworkImage(imgurl),
          backgroundColor: normalText,
        );
}
