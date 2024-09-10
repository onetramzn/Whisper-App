import 'package:chatapp/Screens/StatusPage/HeadOnStatus.dart';
import 'package:chatapp/Screens/StatusPage/OthersStatus.dart';
import 'package:flutter/material.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({Key? key}) : super(key: key);

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 48,
            child: FloatingActionButton(
                backgroundColor: Colors.blueGrey[100],
                elevation: 8,
                onPressed: () {},
                child: Icon(
                  Icons.edit,
                  color: Colors.blueGrey[900],
                )),
          ),
          SizedBox(
            height: 13,
          ),
          FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.greenAccent[700],
            elevation: 5,
            child: Icon(Icons.camera_alt),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SizedBox(
            //   height: 10,
            // ),
            HeadOwnStatus(),
            label("Recent update"),
            OthersStatus(
              name: "Vo Manh Cuong",
              imageName: "assets/2.jpeg",
              time: "04:17",
              isSeen: false, 
              statusNum: 1,
            ),
            OthersStatus(
              name: "Truong Tuan Dat",
              imageName: "assets/3.jpg",
              time: "01:27",
              isSeen: false, 
              statusNum: 2,
            ),
            OthersStatus(
              name: "Dang Truong Nguyen Hao",
              imageName: "assets/1.jpg",
              time: "02:27",
              isSeen: false, 
              statusNum: 3,
            ),
            SizedBox(
              height: 10,
            ),
            label("Viewed update"),
            OthersStatus(
              name: "Vo Manh Cuong",
              imageName: "assets/2.jpeg",
              time: "04:17", 
              isSeen: true, 
              statusNum: 1,
            ),
            OthersStatus(
              name: "Truong Tuan Dat",
              imageName: "assets/3.jpg",
              time: "01:27",
              isSeen: true, 
              statusNum: 2,
            ),
            OthersStatus(
              name: "Dang Truong Nguyen Hao",
              imageName: "assets/1.jpg",
              time: "02:27",
              isSeen: true, 
              statusNum: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget label(String labelname) {
    return Container(
      height: 33,
      width: MediaQuery.of(context).size.width,
      color: Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        child: Text(
          labelname,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
