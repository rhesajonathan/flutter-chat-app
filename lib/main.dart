import 'package:chat_app/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;


  FirebaseUser currentUser;
  
  Future<Null> handleSignIn() async{

    prefs = await SharedPreferences.getInstance();

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    FirebaseUser firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;
    if(firebaseUser != null){
      final QuerySnapshot result = await Firestore.instance.collection('users').where('id',isEqualTo: firebaseUser.uid).getDocuments();
      final List<DocumentSnapshot> documents = result.documents;

      if(documents.length == 0){
        Firestore.instance.collection('users').document(firebaseUser.uid).setData(<String,dynamic>{
          'nickname': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoUrl,
          'id': firebaseUser.uid,
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'chattingWith': null
        });


        currentUser = firebaseUser;
        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoUrl);
      }
      else
      {
        print('success');
        await prefs.setString('id', documents[0]['id'].toString());
        await prefs.setString('nickname', documents[0]['nickname'].toString());
        await prefs.setString('photoUrl', documents[0]['photoUrl'].toString());
        await prefs.setString('aboutMe', documents[0]['aboutMe'].toString());
      }
      Fluttertoast.showToast(msg: 'Sign in success');
     Navigator.pushReplacement<BuildContext,dynamic>(context, MaterialPageRoute(builder: (BuildContext context) => HomeScreen(currentUserId: firebaseUser.uid)));
    }
    else
    {
      print('empty');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body:SizedBox.expand(
        child:Container(
          color:Colors.amber,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:<Widget>[
                Image.asset(
                  'images/logo.png',
                  width:200
                ),
                const Text(
                  'Chatty',
                  style:TextStyle(
                    fontSize: 30
                  )
                ),
                Container(
                  margin:const EdgeInsets.only(top:20),
                  child:FlatButton(
                    onPressed: handleSignIn, 
                    color:Colors.black,
                    textColor: Colors.amber,
                    padding:const EdgeInsets.symmetric(vertical:10,horizontal:50),
                    child:const Text('Login')
                    ),
                )
              ]
            )
        )
      )
    );
  }
}
