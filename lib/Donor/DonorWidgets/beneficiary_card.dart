import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Donor/DonorAlertDialog/DonorAlertDialogs.dart';
import 'package:donaid/Donor/adoption_details_screen.dart';
import 'package:donaid/Models/Adoption.dart';
import 'package:donaid/Models/Beneficiary.dart';
import 'package:donaid/Models/Organization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Models/Subscription.dart';
import '../beneficiary_donate_screen.dart';
import '../updateFavorite.dart';
import 'package:get/get.dart';

class BeneficiaryCard extends StatefulWidget {
  final beneficiary;

  const BeneficiaryCard(this.beneficiary, {Key? key}) : super(key: key);

  @override
  State<BeneficiaryCard> createState() => _BeneficiaryCardState();
}

// Set up the beneficiary card
class _BeneficiaryCardState extends State<BeneficiaryCard> {
  Organization? organization;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  var f = NumberFormat("###,##0.00", "en_US");
  User? loggedInUser;
  var pointlist = [];
  bool favorite = false;
  bool isAdopted=false;

  @override
  void initState() {
    super.initState();
    _getBeneficiaryOrganization();
    _getCurrentUser();
    _getFavorite();
    _getCurrentlyAdopted();
  }

  void _getCurrentUser() {
    loggedInUser = _auth.currentUser;
  }


  _getCurrentlyAdopted()async{
  /*This method gets the StripeSubscriptions record for the logged in donor user.
    * This is so that we can check if the adoption that we are viewing has already been adopted by the user*/
    if(widget.beneficiary is Adoption) {
      var subscriptionsDoc = await _firestore.collection('StripeSubscriptions')
          .doc(_auth.currentUser?.uid)
          .get();
      for (var item in subscriptionsDoc['subscriptionList']) {
        Subscription subscription = Subscription(
          item['adoptionID'],
          item['subscriptionID'],
          item['monthlyAmount'],
        );

        if (subscription.adoptionID == widget.beneficiary.id) {
          isAdopted = true;
          break;
        }
      }
    }

    setState(() {
    });
  }
  // Get the organization's information of this beneficiary from Firebase
  _getBeneficiaryOrganization() async {
    var ret = await _firestore
        .collection('OrganizationUsers')
        .where('uid', isEqualTo: widget.beneficiary.organizationID)
        .get();

    for (var element in ret.docs) {
      organization = Organization(
        organizationName: element.data()['organizationName'],
        uid: element.data()['uid'],
        organizationDescription: element.data()['organizationDescription'],
        country: element.data()['country'],
        gatewayLink: element.data()['gatewayLink'],
      );
    }
  }

  _getFavorite() async {
    if (_auth.currentUser?.email != null) {
      await _firestore
          .collection("Favorite")
          .doc(loggedInUser!.uid)
          .get()
          .then((value) {
        setState(() {
          pointlist = List.from(value['favoriteList']);
        });
      });
    }
  }
  // create the beneficiary card

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      width: 275.0,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(color: Colors.grey.shade300, width: 2.0)),
      child: Column(children: [
        // display icon
        (_auth.currentUser?.email != null && widget.beneficiary is Beneficiary)
        ? Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: Icon(
              pointlist.contains(widget.beneficiary.id.toString())
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: pointlist.contains(widget.beneficiary.id.toString())
                  ? Colors.red
                  : null,
              size: 30,
            ),
            onPressed: () async {
              await updateFavorites(loggedInUser!.uid.toString(),
                  widget.beneficiary.id.toString());
              await _getFavorite();

            },
          ),
        ): Container(height:48),
        (widget.beneficiary is Beneficiary) ?
        Icon(
          Icons.person,
          color: Colors.blue,
          size: 40,
        )
        : (isAdopted)?
        Icon(Icons.handshake, color: Colors.blue, size: 40,)
        :Icon(Icons.handshake_outlined,
        color: Colors.blue,
        size: 40),
        // display beneficiary name populated from Firebase
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            height: 50,
            child: Text(widget.beneficiary.name,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                )),
          ),
        ),
        // display beneficiary biography populated from Firebase
        SizedBox(
            height: 75.0,
            child: Text(
              widget.beneficiary.biography,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            )),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // Display beneficiary amount raised populated from firebase
          Text('\$' + f.format(widget.beneficiary.amountRaised),
              textAlign: TextAlign.left,
              style: const TextStyle(color: Colors.black, fontSize: 15)),
          // Display beneficiary goal amount from firebase
          Text(
            '\$' + f.format(widget.beneficiary.goalAmount),
            textAlign: TextAlign.start,
            style: const TextStyle(color: Colors.black, fontSize: 15),
          ),
        ]),
        // Display beneficiary progress bar
        Container(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              value: (widget.beneficiary.amountRaised /
                  widget.beneficiary.goalAmount),
              minHeight: 10,
            ),
          ),
        ),
        Container(
            margin: const EdgeInsets.only(top: 10.0),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    // For organizations in the United States, navigate to beneficiary's donate screen
                    if (organization?.country == 'United States') {

                      //If beneficiary is not up for adoptions, go to beneficiary donate screen
                      if(widget.beneficiary is Beneficiary ){
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                              return (BeneficiaryDonateScreen(widget.beneficiary));
                            })).then((value) {
                          setState(() {});
                        });
                      }
                      //if the beneficiary is up for adoption, go to the adoptions details screen
                      else if(widget.beneficiary is Adoption){
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                              return (AdoptionDetailsScreen(widget.beneficiary));
                            })).then((value) {
                          setState(() {});
                        });
                      }

                    }
                    // For organizations outside the United States, display the dialog with gateway link
                    else {
                      Map<String, dynamic> charity = {
                        'charityType': 'Beneficiary',
                        'charityID': widget.beneficiary.id,
                        'charityTitle': widget.beneficiary.name
                      };
                      DonorAlertDialogs.paymentLinkPopUp(context, organization!,
                          _auth.currentUser!.uid, charity);
                    }
                  },
                  // Display donate button
                  child: Row(children: [
                    (widget.beneficiary is Beneficiary) ?
                    Container(
                      margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: Text('donate'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          )),
                    )
                        :
                    Container(
                      margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: Text('adopt'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          )),
                    )
                  ]),
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.pink,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            )),
      ]),
    );
  }
}
