import 'dart:convert';
import 'package:donaid/Models/Subscription.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Models/Adoption.dart';
import 'package:donaid/Organization/OrganizationWidget/organization_bottom_navigation.dart';
import 'package:donaid/Organization/OrganizationWidget/organization_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../Services/subscriptions.dart';
import 'edit_adoption.dart';
import 'organization_dashboard.dart';

class OrganizationAdoptionFullScreen extends StatefulWidget {
  final Adoption adoption;
  const OrganizationAdoptionFullScreen(this.adoption, {Key? key})
      : super(key: key);

  @override
  _OrganizationAdoptionFullScreenState createState() =>
      _OrganizationAdoptionFullScreenState();
}

class _OrganizationAdoptionFullScreenState
    extends State<OrganizationAdoptionFullScreen> {
  final _firestore = FirebaseFirestore.instance;
  var f = NumberFormat("###,##0.00", "en_US");
  bool showLoadingSpinner = false;

  @override
  void initState() {
    super.initState();
    _refreshAdoption();
  }

  _refreshAdoption() async {
    // Get current adoption's information from Firebase
    var ret = await _firestore
        .collection('Adoptions')
        .where('id', isEqualTo: widget.adoption.id)
        .get();

    // Update the adoption object with the data from Firebase
    var doc = ret.docs[0];
    widget.adoption.name = doc['name'];
    widget.adoption.biography = doc['biography'];
    widget.adoption.category = doc['category'];
    widget.adoption.goalAmount = doc['goalAmount'].toDouble();
    widget.adoption.active = doc['active'];
    widget.adoption.amountRaised = doc['amountRaised'].toDouble();
    setState(() {});
  }


  _stopAdoption() async {
    setState(() {
      showLoadingSpinner = true;
    });
    // Update the current adoption's active field to false in Firebase
    await _firestore
        .collection('Adoptions')
        .doc(widget.adoption.id)
        .update({'active': false, 'amountRaised':0});

    _endSubscriptions();

    setState(() {
      showLoadingSpinner = false;
    });
  }

  Future<Map<String, dynamic>> _cancelSubscription(String subscriptionId) async {
    //function to cancel subscriptions

    Map<String, dynamic> body = {
      'subscription': subscriptionId,
    };

    var response = await http.post(
        Uri.https('donaidmobileapp.herokuapp.com', '/cancel-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body)
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      throw 'Failed to cancel subscription.';
    }
  }


  _endSubscriptions() async{
    var subscriptions = await _firestore.collection('StripeSubscriptions').get();

    List<String>? userIdList= [];
    List<Subscription>? subscriptionsList=[];

    for(var item in subscriptions.docs){ // iterate through subscriptions collection

      for(var stripeSubscriptionObject in item['subscriptionList']){ //iterate through the subscription list in each document
        if(stripeSubscriptionObject['adoptionID'] == widget.adoption.id){
          Subscription subscription = Subscription(
              stripeSubscriptionObject['adoptionID'],
              stripeSubscriptionObject['subscriptionID'],
              stripeSubscriptionObject['monthlyAmount']
          );

          subscriptionsList.add(subscription); //add subscription id to subscriptionIds
          userIdList.add(item.id); // add user id to userIds
          break;//break out of inner loop
        }
      }

    }

    //iterate through all subscriptions
    for(var subscription in subscriptionsList){
      deleteSubscription(userIdList.elementAt(subscriptionsList.indexOf(subscription)), subscription);
      _cancelSubscription(subscription.subscriptionsID);
    }

  }

  // Update the current adoption's active field to true in Firebase
  _resumeAdoption() async {
    await _firestore
        .collection('Adoptions')
        .doc(widget.adoption.id)
        .update({'active': true});
  }

  // Delete current adoption in Firebase
  _deleteAdoption() async {
    await _firestore.collection('Adoptions').doc(widget.adoption.id).delete();
  }

  // Display stop charity confirmation dialog
  Future<void> _stopCharityConfirm() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title:  Center(
              child: Text('are_you_sure?'.tr),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
            ),
            content: Text(
                'Stopping this charity will make it not visible to donors. Once you stop this charity you can reactivate it from the Inactive Charities page. Would you like to continue with stopping this charity?'.tr),
            actions: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                  Center(
                    // Display 'yes' option
                    // On pressed, stop adoption charity and go back to adoption details
                    child: TextButton(
                      onPressed: () {
                        _stopAdoption();
                        Navigator.pop(context);
                        _refreshAdoption();
                      },
                      child: Text('yes'.tr),
                    ),
                  ),
                    // Display 'no' option
                    // On pressed, go back to adoption details
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('no'.tr),
                    ),
                  ),
                ]
              ),

            ],
          );
        });
  }

  // Display resume charity confirmation dialog
  Future<void> _resumeCharityConfirm() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title:  Center(
              child: Text('are_you_sure?'.tr),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
            ),
            content: Text(
                'resuming_adoption_charity_would_you_like_to_continue'.tr),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Center(
                    // Display 'yes' option
                    // On pressed, resume adoption charity and go back to adoption details
                    child: TextButton(
                      onPressed: () {
                        _resumeAdoption();
                        Navigator.pop(context);
                        _refreshAdoption();
                      },
                      child: Text('yes'.tr),
                    ),
                  ),
                  // Display 'no' option
                  // On pressed, go back to adoption details
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('no'.tr),
                    ),
                  ),
                ],
              ),

            ],
          );
        });
  }

  // Display delete charity confirmation dialog
  Future<void> _deleteCharityConfirm() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title:  Center(
              child: Text('are_you_sure?'.tr),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
            ),
            //doubt
            content: Text(
                'Deleting this charity will completely remove it from the application. Would you like to continue?'.tr),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Center(
                    // Display 'yes' option
                    // On pressed, delete adoption charity and go back to organization dashboard
                    child: TextButton(
                      onPressed: () {
                        _deleteAdoption();
                        Navigator.popUntil(context, ModalRoute.withName(OrganizationDashboard.id));
                      },
                      child:  Text('yes'.tr),
                    ),
                  ),
                  // Display 'no' option
                  // On pressed, go back to adoption details
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child:  Text('no'.tr),
                    ),
                  ),
                ],
              ),

            ],
          );
        });
  }

  _beneficiaryFullBody() {
    return ModalProgressHUD(
      inAsyncCall: showLoadingSpinner,
      child: Center(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                    height: 100, child: Image.asset('assets/DONAID_LOGO.png')),
                SizedBox(height: 10),
                Text(
                  widget.adoption.name,
                  style: TextStyle(fontSize: 25),
                ),
                Text(
                  widget.adoption.biography,
                  style: TextStyle(fontSize: 18),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$' + f.format(widget.adoption.amountRaised),
                          style:
                              const TextStyle(color: Colors.black, fontSize: 18),
                        ),
                        Text(
                          '\$' + f.format(widget.adoption.goalAmount),
                          style:
                              const TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                        value: (widget.adoption.amountRaised /
                            widget.adoption.goalAmount),
                        minHeight: 25,
                      ),
                    ),
                  ),
                ),
                Column(
                    children: (widget.adoption.amountRaised <
                            widget.adoption.goalAmount)
                        ? [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widget.adoption.amountRaised == 0
                                  ? [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 75, 20, 0),
                                        child: Material(
                                            elevation: 5.0,
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(32.0),
                                            child: MaterialButton(
                                                child: Text(
                                                  'edit'.tr,
                                                  style: const TextStyle(
                                                    fontSize: 25,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  Navigator.push(context,
                                                      MaterialPageRoute(
                                                          builder: (context) {
                                                    return EditAdoption(
                                                        adoption:
                                                            widget.adoption);
                                                  })).then((value) =>
                                                      _refreshAdoption());
                                                })),
                                      ),
                                      Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              20, 10, 20, 0),
                                          child: (widget.adoption.active)
                                              ? Material(
                                                  elevation: 5.0,
                                                  color: Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(32.0),
                                                  child: MaterialButton(
                                                      child: Text(
                                                        'stop_charity'.tr,
                                                        style: const TextStyle(
                                                          fontSize: 25,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        _stopCharityConfirm();
                                                      }))
                                              : (!widget.adoption.active)
                                                  ? Material(
                                                      elevation: 5.0,
                                                      color: Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              32.0),
                                                      child: MaterialButton(
                                                          child: Text(
                                                            'resume_charity'.tr,
                                                            style: const TextStyle(
                                                              fontSize: 25,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                          onPressed: () async {
                                                            _resumeCharityConfirm();
                                                          }))
                                                  : Container()),
Container(
  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
  child:  Material(
        elevation: 5.0,
        color: Colors.red,
        borderRadius: BorderRadius.circular(32.0),
        child: MaterialButton(
            child: Text(
              'Delete'.tr,
              style: TextStyle(
                fontSize: 25,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              _deleteCharityConfirm();
            }
)))
                                    ]
                                  : [
                                      Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              20, 10, 20, 0),
                                          child: (widget.adoption.active)
                                              ? Material(
                                                  elevation: 5.0,
                                                  color: Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(32.0),
                                                  child: MaterialButton(
                                                      child: Text(
                                                        'stop_charity'.tr,
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        _stopCharityConfirm();
                                                      }))
                                              : (!widget.adoption.active)
                                                  ? Material(
                                                      elevation: 5.0,
                                                      color: Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              32.0),
                                                      child: MaterialButton(
                                                          child:  Text(
                                                            'resume_charity'.tr,
                                                            style: const TextStyle(
                                                              fontSize: 25,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                          onPressed: () async {
                                                            _resumeCharityConfirm();
                                                          }))
                                                  : Container())
                                    ],
                            )
                          ]
                        : [
                            const SizedBox(height: 50),
                             Center(
                              child: Text(
                                'This charity has reached it\'s goal!'.tr,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            )
                          ]),
              ]))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.adoption.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: const OrganizationDrawer(),
      body: _beneficiaryFullBody(),
      bottomNavigationBar: const OrganizationBottomNavigation(),
    );
  }
}
