import 'package:chatapp/CustomUI/ButtonCard.dart';
import 'package:chatapp/CustomUI/ContactCard.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Screens/CreateGroup.dart';
import 'package:flutter/material.dart';

class SelectContact extends StatefulWidget {
  SelectContact({Key? key}) : super(key: key);

  @override
  _SelectContactState createState() => _SelectContactState();
}

class _SelectContactState extends State<SelectContact> {
  @override
  Widget build(BuildContext context) {
    List<ChatModel> contacts = [
  ChatModel(name: "Dev Stack", status: "A full stack developer", icon: '', time: '12:00 PM', currentMessage: 'Hey, check this out!', id: 0),
  ChatModel(name: "Balram", status: "Flutter Developer...........", icon: '', time: '1:30 PM', currentMessage: 'Let\'s catch up soon!', id: 1),
  ChatModel(name: "Saket", status: "Web developer...", icon: '', time: '3:45 PM', currentMessage: 'New project idea!', id: 2),
  ChatModel(name: "Bhanu Dev", status: "App developer....", icon: '', time: '11:15 AM', currentMessage: 'Finished the module.', id: 3),
  ChatModel(name: "Collins", status: "React developer..", icon: '', time: '5:50 PM', currentMessage: 'Push the changes.', id: 4),
  ChatModel(name: "Kishor", status: "Full Stack Web", icon: '', time: '9:20 AM', currentMessage: 'Code review meeting.', id: 5),
  ChatModel(name: "Testing1", status: "Example work", icon: '', time: '2:00 PM', currentMessage: 'Test case passed.', id: 6),
  ChatModel(name: "Testing2", status: "Sharing is caring", icon: '', time: '4:10 PM', currentMessage: 'Here\'s the document.', id: 7),
  ChatModel(name: "Divyanshu", status: ".....", icon: '', time: '6:30 PM', currentMessage: 'Let\'s discuss.', id: 8),
  ChatModel(name: "Helper", status: "Love you Mom Dad", icon: '', time: '8:45 AM', currentMessage: 'Happy birthday!', id: 9),
  ChatModel(name: "Tester", status: "I find the bugs", icon: '', time: '7:00 PM', currentMessage: 'Found a bug in the system.', id: 10),
];

    return Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Contact",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "256 contacts",
                style: TextStyle(
                  fontSize: 13,
                ),
              )
            ],
          ),
          actions: [
            IconButton(
                icon: Icon(
                  Icons.search,
                  size: 26,
                ),
                onPressed: () {}),
            PopupMenuButton<String>(
              padding: EdgeInsets.all(0),
              onSelected: (value) {
                print(value);
              },
              itemBuilder: (BuildContext contesxt) {
                return [
                  PopupMenuItem(
                    child: Text("Invite a friend"),
                    value: "Invite a friend",
                  ),
                  PopupMenuItem(
                    child: Text("Contacts"),
                    value: "Contacts",
                  ),
                  PopupMenuItem(
                    child: Text("Refresh"),
                    value: "Refresh",
                  ),
                  PopupMenuItem(
                    child: Text("Help"),
                    value: "Help",
                  ),
                ];
              },
            ),
          ],
        ),
        body: ListView.builder(
            itemCount: contacts.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (builder) => CreateGroup()));
                  },
                  child: ButtonCard(
                    icon: Icons.group,
                    name: "New group",
                  ),
                );
              } else if (index == 1) {
                return ButtonCard(
                  icon: Icons.person_add,
                  name: "New contact",
                );
              }
              return ContactCard(
                contact: contacts[index - 2],
              );
            }));
  }
}
