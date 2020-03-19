
import 'package:chat_app/chat.dart';
import 'package:chat_app/components/profilePhoto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key,this.currentUserId}):super(key:key);

  final String currentUserId;
  
  @override
  _HomeScreenState createState() => _HomeScreenState(currentUserId:currentUserId);
}

class _HomeScreenState extends State<HomeScreen> {

  _HomeScreenState({Key key,this.currentUserId});

  final String currentUserId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text(
          'Home',
          style:TextStyle(color: Colors.white),
          ),
        backgroundColor: Colors.amber,
      ),
      body:Container(
        child:StreamBuilder(
          stream: Firestore.instance.collection('users').snapshots(),
          builder:(context,snapshot){
            return _buildContact(context,snapshot.data.documents);
          }
        )
      )
    );
  }


  Widget _buildContact(BuildContext context, List<DocumentSnapshot> documents){
    return ListView.builder(
      itemBuilder: (context, i){
        return _buildRow(context,documents[i]);
      },
      itemCount: documents.length,
    );
  }

  Widget _buildRow(BuildContext context,DocumentSnapshot document){
    if(document['id'] == currentUserId){
      return Container();
    }
    else{
      return Column(
        children:[
          ListTile(
            leading: ProfilePhoto(document['photoUrl'],'medium'),
            title: Text(document['nickname']),
            subtitle: Text('Here is a second line'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(document['nickname'],document['id'],document['photoUrl']))),
          ),
          Divider()
        ]
      );
    }
  }
}




