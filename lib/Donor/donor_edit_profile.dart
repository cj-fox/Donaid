import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Donor/donor_dashboard.dart';
import 'package:donaid/Models/Donor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'donor_profile.dart';

class DonorEditProfile extends StatefulWidget {
  static const id = 'donor_edit_profile';

  const DonorEditProfile({Key? key}) : super(key: key);

  @override
  _DonorEditProfileState createState() => _DonorEditProfileState();
}

class _DonorEditProfileState extends State<DonorEditProfile> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  final _firestore = FirebaseFirestore.instance;
  Donor donor = Donor.c1();
  TextEditingController? _firstNameController;
  TextEditingController? _lastNameController;
  TextEditingController? _phoneNumberController;

  static final phoneNumberRegExp =
      RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _getDonorInformation();
  }

  void _getCurrentUser() {
    loggedInUser = _auth.currentUser;
  }

  _getDonorInformation() async {
    var ret = await _firestore
        .collection('DonorUsers')
        .where('uid', isEqualTo: loggedInUser?.uid)
        .get();
    final doc = ret.docs[0];
    donor = Donor(
        email: doc['email'],
        firstName: doc['firstName'],
        lastName: doc['lastName'],
        phoneNumber: doc['phoneNumber'],
        id: doc['id']
    );
    setState(() {});
  }

  _updateDonorInformation() async {
    _firestore.collection('DonorUsers').doc(donor.id).update({
      "firstName": donor.firstName,
      "lastName": donor.lastName,
      "phoneNumber": donor.phoneNumber
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title:  Text('edit_profile'.tr),
          leadingWidth: 80,
          leading: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, DonorProfile.id);
            },
            child:  Text('cancel'.tr,
                style: TextStyle(fontSize: 15.0, color: Colors.white)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _submitForm();
                Navigator.pop(context);
              },
              child:  Text('save'.tr,
                  style: TextStyle(fontSize: 15.0, color: Colors.white)),
            ),
          ]),
      body: _body(),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Widget _buildFirstNameField() {
    _firstNameController = TextEditingController(text: donor.firstName);
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
              label: Center(
                child: RichText(
                  text:  TextSpan(
                    text: 'first_name'.tr,
                    style: TextStyle(
                        color: Colors.black, fontSize: 20.0),
                  ),
                ),
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0)),
              )),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'please_enter_first_name.'.tr;
            }
            return null;
          },
          onSaved: (value) {
            donor.firstName = value!;
          },
        ));
  }

  Widget _buildLastNameField() {
    _lastNameController = TextEditingController(text: donor.lastName);
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
              label: Center(
                child: RichText(
                  text:  TextSpan(
                    text: 'last_name'.tr,
                    style: TextStyle(
                        color: Colors.black, fontSize: 20.0),
                  ),
                ),
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0)),
              )),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'please_enter_last_name.'.tr;
            }
            return null;
          },
          onSaved: (value) {
            donor.lastName = value!;
          },
        ));
  }

  Widget _buildPhoneNumberField() {
    _phoneNumberController = TextEditingController(text: donor.phoneNumber);
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: _phoneNumberController,
          decoration: InputDecoration(
              label: Center(
                child: RichText(
                  text:  TextSpan(
                    text: 'phone_number'.tr,
                    style: TextStyle(
                        color: Colors.black, fontSize: 20.0),
                  ),
                ),
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0)),
              )),
          validator: (value) {
            if (value!.isEmpty) {
              return "please_enter_your_phone_number.".tr;
            } else if (!phoneNumberRegExp.hasMatch(value)) {
              return "please_enter_a_valid_phone_number.".tr;
            } else {
              return null;
            }
          },
          onSaved: (value) {
            donor.phoneNumber = value!;
          },
        ));
  }

  _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    _updateDonorInformation();
  }

  _body() {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildFirstNameField(),
              _buildLastNameField(),
              _buildPhoneNumberField(),
            ],
          ),
        ),
      ),
    );
  }

  _bottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              enableFeedback: false,
              onPressed: () {
                Navigator.pushNamed(context, DonorDashboard.id);
              },
              icon: const Icon(Icons.home, color: Colors.white, size: 35),
            ),
            const Text('Home',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ]),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              enableFeedback: false,
              onPressed: () {},
              icon: const Icon(
                Icons.search,
                color: Colors.white,
                size: 35,
              ),
            ),
             Text('search'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ]),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              enableFeedback: false,
              onPressed: () {},
              icon: const Icon(Icons.notifications,
                  color: Colors.white, size: 35),
            ),
             Text('notifications'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ]),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              enableFeedback: false,
              onPressed: () {},
              icon: const Icon(Icons.message, color: Colors.white, size: 35),
            ),
             Text('message'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ]),
        ],
      ),
    );
  }
}
