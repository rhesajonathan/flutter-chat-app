
import 'package:flutter/material.dart';

class ProfilePhoto extends StatelessWidget {

  final String photoUrl;
  final String size;

  const ProfilePhoto(this.photoUrl, this.size);


  @override
  Widget build(BuildContext context) {
    double sizePhoto;

    if(size == 'small'){
      sizePhoto = 40;
    }
    else if(size == 'medium'){
      sizePhoto = 56;
    }

    return Container(
      width: sizePhoto,
      height: sizePhoto,
      decoration: new BoxDecoration(
        shape: BoxShape.circle,
        image: new DecorationImage(
          fit:BoxFit.cover,
          image: new NetworkImage(photoUrl)
        )
      )
    );
  }
}