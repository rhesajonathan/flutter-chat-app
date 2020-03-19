
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/components/profilePhoto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatelessWidget {

  final String nickName;
  final String peerId;
  final String photoUrl;
  const ChatScreen(this.nickName,this.peerId,this.photoUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text(
          this.nickName,
          style:TextStyle(color: Colors.white),
          ),
        backgroundColor: Colors.amber,
      ),
      body: ChatContent(photoUrl,peerId),
    );
  }
}

class ChatContent extends StatefulWidget {

  final String photoUrl;
  final String peerId;
  ChatContent(this.photoUrl,this.peerId);

  @override
  _ChatContentState createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {

  String id;

  String groupChatId;
  SharedPreferences prefs;
  var listMessage;

  File imageFile;


  final TextEditingController textEditingController = new TextEditingController();

  void initState(){
    super.initState();

    readLocal();
  }

  readLocal() async{
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    String peerId = widget.peerId;
    print(widget.peerId);
    if(id.hashCode <= peerId.hashCode){
      groupChatId = '$id-$peerId';
    }
    else{
      groupChatId = '$peerId-$id';
    }

    Firestore.instance.collection('users').document(id).updateData({'chattingWith':widget.peerId});
    setState(() {});
  }

  Future getImage() async{
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if(imageFile != null){
      uploadFile();
    }
  }

  Future uploadFile() async{
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl){
      onSendMessage(downloadUrl, 1);
    });

  }

  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': widget.peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type
          },
        );
      });
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
     children: [
        _buildChatList(),
        _buildInput()
     ]
    );
  }

  Widget _buildInput(){
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        border:Border(
          top:BorderSide(
            color:Colors.grey,
            width:0.5,
            ),
          )
      ),
      child: Row(
        children: <Widget>[
          Material(
            child: new Container(
              child: IconButton(
                icon:Icon(Icons.image), 
                onPressed: getImage,)
            ),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration.collapsed(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color:Colors.grey)
              ),
              controller: textEditingController,
            )
          ),
          Material(
            child:Container(
              child:IconButton(
                icon:Icon(Icons.send),
                onPressed:(){
                  onSendMessage(textEditingController.text, 0);
                }
              )
            )
          )
        ],
      ),
    );
  }

  Widget _buildChatList(){
    return Flexible(
      child:StreamBuilder(
        stream: Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
        builder:(context,snapshot){
            print(groupChatId);
            listMessage = snapshot.data.documents;
            return ListView.builder(
              padding: EdgeInsets.all(10),
              itemBuilder:(context,i) => _buildItem(i,snapshot.data.documents[i]), 
              itemCount: snapshot.data.documents.length,
              reverse: true,
              );
        }
      )
    );
  }


  Widget _buildItem(int index, DocumentSnapshot document){
    if(document['idFrom'] == id){
      return _buildChatBubble(document);
    }
    else
    {
      return _buildChatBubblePeer(document);
    }
  }

  Widget _buildChatBubble(DocumentSnapshot document){

    return document['type'] == 0 ? 
      Container(
        width:200,
        child:Text(document['content']),
        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
        margin: EdgeInsets.only(left:150,top:15),
        decoration: BoxDecoration(color:Colors.grey[350],borderRadius:BorderRadius.circular(8)),
      )
    :
      Container(
        width:200,
        height: 200,
        margin: EdgeInsets.only(left:150,top:15),
        child:Material(
          child:CachedNetworkImage(
            imageUrl: document['content'],
            fit:BoxFit.cover,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          clipBehavior: Clip.hardEdge,
        )
      );
  }

  Widget _buildChatBubblePeer(DocumentSnapshot document){
    return document['type'] == 0 ? Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Container(
          margin:EdgeInsets.only(top:15),
          child:ProfilePhoto(widget.photoUrl, 'small')
        ),
        Container(
          width:200,
          child:Text(document['content']),
          padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
          margin: EdgeInsets.only(left:10,top:15),
          decoration: BoxDecoration(color:Colors.amber,borderRadius:BorderRadius.circular(8)),
        )
      ]
    )
    :
    Container(
      width:200,
      height: 200,
      margin: EdgeInsets.only(left:10,top:15),
      child:Material(
        child:CachedNetworkImage(
          imageUrl: document['content'],
          fit:BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        clipBehavior: Clip.hardEdge,
      )
    );
  }
}
