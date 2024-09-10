import 'package:chatapp/CustomUI/AvtarCard.dart';
import 'package:chatapp/CustomUI/ContactCard.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:flutter/material.dart';

class CreateGroup extends StatefulWidget {
  CreateGroup({Key? key}) : super(key: key);

  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
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

  List<ChatModel> groupmember = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "New Group",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Add participants",
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
            backgroundColor: Color(0xFF128C7E),
            onPressed: () {},
            child: Icon(Icons.arrow_forward)),
        body: Stack(
          children: [
            ListView.builder(
                itemCount: contacts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      height: groupmember.length > 0 ? 90 : 10,
                    );
                  }
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (contacts[index - 1].select == true) {
                          groupmember.remove(contacts[index - 1]);
                          contacts[index - 1].select = false;
                        } else {
                          groupmember.add(contacts[index - 1]);
                          contacts[index - 1].select = true;
                        }
                      });
                    },
                    child: ContactCard(
                      contact: contacts[index - 1],
                    ),
                  );
                }),
            groupmember.length > 0
                ? Align(
                    child: Column(
                      children: [
                        Container(
                          height: 75,
                          color: Colors.white,
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: contacts.length,
                              itemBuilder: (context, index) {
                                if (contacts[index].select == true)
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        groupmember.remove(contacts[index]);
                                        contacts[index].select = false;
                                      });
                                    },
                                    child: AvatarCard(
                                      chatModel: contacts[index],
                                    ),
                                  );
                                return Container();
                              }),
                        ),
                        Divider(
                          thickness: 1,
                        ),
                      ],
                    ),
                    alignment: Alignment.topCenter,
                  )
                : Container(),
          ],
        ));
  }
}
