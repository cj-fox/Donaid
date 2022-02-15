import 'package:donaid/Models/CharityCategory.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'category_campaigns_screen.dart';

class CategoryScreenTile extends StatelessWidget {
  final CharityCategory charityCategory;
  final _firebaseStorage = FirebaseStorage.instance;
  CategoryScreenTile({Key? key, required this.charityCategory})
      : super(key: key);

  Future<String> downloadURL(String imageName) async {
    String downloadURL = await _firebaseStorage
            .ref()
            .child('icons/')
            .child('$imageName.png').getDownloadURL();
    return downloadURL;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        print(charityCategory.name);
        //TODO: Direct to that category page
        Navigator.push(context, MaterialPageRoute(
          builder: (context){
            return(CategoryCampaignsScreen(categoryName: charityCategory.name));
        }
        ));
      },
      child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
              decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Row(children: [
                  const SizedBox(
                    width: 5,
                  ),
                  FutureBuilder(
                      future: downloadURL(charityCategory.name),
                      builder:
                          (BuildContext context, AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return SizedBox(
                            width: 25,
                            height: 25,
                            child: Image.network(
                              snapshot.data!,
                              fit: BoxFit.contain,
                          ),
                            );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting ||
                            !snapshot.hasData) {}
                        return Container();
                      }),
                  const SizedBox(
                    width: 5,
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: Text(charityCategory.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                        )),
                  )
                ]),
              ))),
    );
  }
}
