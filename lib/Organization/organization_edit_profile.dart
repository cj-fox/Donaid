import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Donor/donor_dashboard.dart';
import 'package:donaid/Models/Organization.dart';
import 'package:donaid/Organization/organization_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrganizationEditProfile extends StatefulWidget {
  static const id = 'organization_edit_profile';

  const OrganizationEditProfile({Key? key}) : super(key: key);

  @override
  _OrganizationEditProfileState createState() => _OrganizationEditProfileState();
}

class _OrganizationEditProfileState extends State<OrganizationEditProfile> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  final _firestore = FirebaseFirestore.instance;
  Organization organization = Organization.c1();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController? _organizationNameController;
  TextEditingController? _phoneNumberController;
  TextEditingController? _organizationDescriptionController;
  TextEditingController? _countryController;
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
        gatewayLink: doc['gatewayLink']
    );
    setState(() {});
  }

  _updateOrganizationInformation() async {
    var ret = await _firestore
        .collection('OrganizationUsers')
        .where('uid', isEqualTo: loggedInUser?.uid)
        .get();
    final doc = ret.docs[0];
    _firestore.collection('OrganizationUsers').doc(doc.id).update({
      "organizationName": organization.organizationName,
      "phoneNumber": organization.phoneNumber,
      "organizationDescription": organization.organizationDescription,
      "country": organization.country,
      "gatewayLink": organization.gatewayLink
    }).whenComplete(_goToProfilePage);
  }

  _goToProfilePage(){
    Navigator.pushNamed(context, OrganizationProfile.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: const Text('Edit Profile'),
          leadingWidth: 80,
          leading: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, OrganizationProfile.id);
              },
              child: const Text('Cancel',
                  style: TextStyle(fontSize: 15.0, color: Colors.white)),
            ),
          actions: [
            TextButton(
              onPressed: () {
                _submitForm();
                _updateOrganizationInformation();
              },
              child: const Text('Save',
                  style: TextStyle(fontSize: 15.0, color: Colors.white)),
            ),
          ]),
      body: _body(),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }



  Widget _buildOrganizationNameField() {
    _organizationNameController = TextEditingController(text: organization.organizationName);
    return Padding(
        padding: const EdgeInsets.all(8.0),
    child: TextFormField(
      controller: _organizationNameController,
      decoration: const InputDecoration(
        labelText: 'Name',
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(32.0)),
          )
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter organization\'s name.';
        }
        return null;
      },
      onSaved: (value) {
        organization.organizationName = value!;
      },
    ));
  }

  Widget _buildPhoneNumberField() {
    _phoneNumberController = TextEditingController(text: organization.phoneNumber);
    return Padding(
        padding: const EdgeInsets.all(8.0),
    child: TextFormField(
      controller: _phoneNumberController,
      decoration: const InputDecoration(
        labelText: 'Phone number',
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(32.0)),
          )
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return "Please enter your phone number.";
        } else if (!phoneNumberRegExp.hasMatch(value)) {
          return "Please enter a valid phone number.";
        } else {
          return null;
        }
      },
      onSaved: (value) {
        organization.phoneNumber = value!;
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
        onSaved: (value) {
          organization.organizationDescription = value;
        },
        textAlign: TextAlign.center,
        decoration: InputDecoration(
            label: Center(
              child: RichText(
                text: const TextSpan(
                  text: 'Organization Description',
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

  Widget _buildCountryField() {
    _countryController = TextEditingController(text: organization.country);
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(32.0)),
              )
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter country.';
            }
            return null;
          },
          onSaved: (value) {
            organization.country = value!;
          },
        ));
  }

  Widget _buildGatewayLinkField() {
    _gatewayLinkController = TextEditingController(text: organization.gatewayLink);
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: _gatewayLinkController,
          decoration: const InputDecoration(
              labelText: 'Gateway Link',
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(32.0)),
              )
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter gateway link.';
            }
            return null;
          },
          onSaved: (value) {
            organization.gatewayLink = value!;
          },
        ));
  }

  _submitForm(){
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
  }

  _body() {
    return SingleChildScrollView(
      child: Container(
      // decoration: BoxDecoration(
      // color: Colors.blueGrey.shade50,),
        margin: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildOrganizationNameField(),
              _buildPhoneNumberField(),
              _buildOrganizationDescriptionField(),
              _buildCountryField(),
              _buildGatewayLinkField()

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
            const Text('Search',
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
            const Text('Notifications',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ]),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              enableFeedback: false,
              onPressed: () {},
              icon: const Icon(Icons.message, color: Colors.white, size: 35),
            ),
            const Text('Messages',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ]),
        ],
      ),
    );
  }
}
