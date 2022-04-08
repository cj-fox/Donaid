import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Models/Organization.dart';
import 'package:donaid/Organization/OrganizationWidget/organization_bottom_navigation.dart';
import 'package:donaid/Organization/organization_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

class OrganizationEditProfile extends StatefulWidget {
  static const id = 'organization_edit_profile';

  const OrganizationEditProfile({Key? key}) : super(key: key);

  @override
  _OrganizationEditProfileState createState() => _OrganizationEditProfileState();
}

class _OrganizationEditProfileState extends State<OrganizationEditProfile> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final _auth = FirebaseAuth.instance;
  final _firebaseStorage = FirebaseStorage.instance;
  User? loggedInUser;
  final _firestore = FirebaseFirestore.instance;
  Organization organization = Organization.c1();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _profilePicture;
  String _uploadedFileURL="";

  TextEditingController? _organizationNameController;
  TextEditingController? _phoneNumberController;
  TextEditingController? _organizationDescriptionController;
  TextEditingController? _gatewayLinkController;

  static final phoneNumberRegExp =
      RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _getOrganizationInformation();
  }

  void _getCurrentUser() {
    loggedInUser = _auth.currentUser;
  }

  Future chooseFile() async {
    await _imagePicker.pickImage(source: ImageSource.gallery).then((image) {
      setState(() {
        _profilePicture = image;
      });
    });
  }

  Future uploadFile() async {
    File file = File(_profilePicture!.path);

    final storageReference = _firebaseStorage
        .ref()
        .child('profilePictures/')
        .child('${_auth.currentUser?.uid}');

    await storageReference.putFile(file);
    var fileURL = await storageReference.getDownloadURL();
    _uploadedFileURL = fileURL;
  }

  _getOrganizationInformation() async {
    var ret = await _firestore.collection('OrganizationUsers').where('uid', isEqualTo: loggedInUser?.uid).get();
    final doc = ret.docs[0];
    organization = Organization(
        organizationEmail: doc['email'],
        organizationName: doc['organizationName'],
        phoneNumber: doc['phoneNumber'],
        uid: doc['uid'],
        organizationDescription: doc['organizationDescription'],
        country: doc['country'],
        gatewayLink: doc['gatewayLink'],
        id: doc["id"],
        profilePictureDownloadURL: doc['profilePictureDownloadURL']
    );
    setState(() {});
  }

  _updateOrganizationInformation() async {
    if(_profilePicture!=null) {
      await uploadFile();

      _firestore.collection('OrganizationUsers').doc(organization.id).update({
        "organizationName": _organizationNameController?.text,
        "phoneNumber": _phoneNumberController?.text,
        "organizationDescription": _organizationDescriptionController?.text,
        "gatewayLink": _gatewayLinkController?.text,
        "profilePictureDownloadURL": _uploadedFileURL
      });
    }
    else{
      _firestore.collection('OrganizationUsers').doc(organization.id).update({
        "organizationName": _organizationNameController?.text,
        "phoneNumber": _phoneNumberController?.text,
        "organizationDescription": _organizationDescriptionController?.text,
        "gatewayLink": _gatewayLinkController?.text,
      });
    }
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
                Navigator.pop(context);
              },
              child:  Text('cancel'.tr,
                  style: TextStyle(fontSize: 15.0, color: Colors.white)),
            ),
          actions: [
            TextButton(
              onPressed: () {
                _submitForm();
              },
              child:  Text('save'.tr,
                  style: TextStyle(fontSize: 15.0, color: Colors.white)),
            ),
          ]),
      body: _body(),
      bottomNavigationBar: OrganizationBottomNavigation(),
    );
  }


  Widget _buildProfilePictureUploadField(){
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
      child: GestureDetector(
        onTap: () async{
          chooseFile();
        },
        child:
        (organization.profilePictureDownloadURL.toString().isEmpty)
        ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:  [
            Icon(Icons.upload),
            Text('upload_profile_picture_or_logo.'.tr),
          ],
        )
        : (organization.profilePictureDownloadURL.toString().isNotEmpty)
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Image.network(
                organization.profilePictureDownloadURL.toString(),
                fit: BoxFit.contain,
              ),),
          ],
        )
            : Container(),
      ),
    );
  }
  Widget _buildOrganizationNameField() {
    _organizationNameController = TextEditingController(text: organization.organizationName);
    return Padding(
        padding: const EdgeInsets.all(8.0),
    child: TextFormField(
      controller: _organizationNameController,
      decoration: InputDecoration(
          label: Center(
            child: RichText(
              text:  TextSpan(
                text: 'name'.tr,
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
          //doubt
          return 'Please enter organization\'s name.';
        }
        return null;
      },
    ));
  }

  Widget _buildPhoneNumberField() {
    _phoneNumberController = TextEditingController(text: organization.phoneNumber);
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
    ));
  }


  Widget _buildOrganizationDescriptionField() {
    _organizationDescriptionController = TextEditingController(text: organization.organizationDescription);
    return  Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _organizationDescriptionController,
        minLines: 2,
        maxLines: 5,
        maxLength: 240,
        onChanged: (value) {
          organization.organizationDescription = value;
        },
        decoration: InputDecoration(
            label: Center(
              child: RichText(
                text:  TextSpan(
                  text: 'organization_description'.tr,
                  style: TextStyle(
                      color: Colors.black, fontSize: 20.0),
                ),
              ),
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0)),
            )),
      ),
    );
  }

  Widget _buildGatewayLinkField() {
    _gatewayLinkController = TextEditingController(text: organization.gatewayLink);
    if(organization.country != "United States") {
      return Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            controller: _gatewayLinkController,
            decoration: InputDecoration(
                label: Center(
                  child: RichText(
                    text:  TextSpan(
                      text: 'gateway_link'.tr,
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
                return 'please_enter_gateway_link.'.tr;
              }
              return null;
            },
          ));
    }
    else{
      return Container();
    }
  }

  _submitForm() async{
    if (!_formKey.currentState!.validate()) {
      return;
    }
    else{
      await _updateOrganizationInformation();
      Navigator.pop(context,true);
    }
    _formKey.currentState!.save();
  }
  Widget _buildUnitedStatesEditProfile(){
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildProfilePictureUploadField(),
              _buildOrganizationNameField(),
              _buildPhoneNumberField(),
              _buildOrganizationDescriptionField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutsideUnitedStatesEditProfile(){
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildProfilePictureUploadField(),
              _buildOrganizationNameField(),
              _buildPhoneNumberField(),
              _buildOrganizationDescriptionField(),
              _buildGatewayLinkField()
            ],
          ),
        ),
      ),
    );
  }

  _body() {
    if(organization.country == 'United States'){
      return _buildUnitedStatesEditProfile();
    }
    else{
      return _buildOutsideUnitedStatesEditProfile();
    }
  }

}
