import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Donor/DonorWidgets/category_screen_tile.dart';
import 'package:donaid/Donor/DonorWidgets/donor_bottom_navigation_bar.dart';
import 'package:donaid/Donor/DonorWidgets/donor_drawer.dart';
import 'package:donaid/Models/CharityCategory.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoriesScreen extends StatefulWidget {
  static const id = 'categories_screen';
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _firestore = FirebaseFirestore.instance;

  List<CharityCategory> charityCategories=[];


  @override
  void initState(){
    super.initState();
    _getCharityCategories();
  }

  _getCharityCategories() async {
    //Get all charity categories from the database
    var ret = await _firestore.collection('CharityCategories').get();
    for (var element in ret.docs) {
      CharityCategory charityCategory = CharityCategory(
          name: element.data()['name'],
          id: element.data()['id'],
          iconDownloadURL: element.data()['iconDownloadURL']
      );
      charityCategories.add(charityCategory);
    }
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('categories'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: const DonorDrawer(),
      body: _categoriesBody(),
      bottomNavigationBar:  DonorBottomNavigationBar(),
    );
  }

  _categoriesBody(){
    //Create a grid view to show all of the categories
    return GridView.builder(
      itemCount: charityCategories.length,
      itemBuilder: (BuildContext context, int index) {
        return CategoryScreenTile(charityCategory: charityCategories[index]);
      },
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1),

    );
  }
}
