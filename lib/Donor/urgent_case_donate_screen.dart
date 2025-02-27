import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Donor/updateFavorite.dart';
import 'package:donaid/Models/UrgentCase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:overlay_support/overlay_support.dart';
import 'DonorWidgets/donor_bottom_navigation_bar.dart';
import 'DonorWidgets/donor_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:get/get.dart';


class UrgentCaseDonateScreen extends StatefulWidget {
  UrgentCase urgentCase;
  UrgentCaseDonateScreen(this.urgentCase, {Key? key}) : super(key: key);

  @override
  _UrgentCaseDonateScreenState createState() => _UrgentCaseDonateScreenState();
}

class _UrgentCaseDonateScreenState extends State<UrgentCaseDonateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Map<String, dynamic>? paymentIntentData;
  String donationAmount = "";
  bool showLoadingSpinner = false;
  var f = NumberFormat("###,##0.00", "en_US");
  User? loggedInUser;
  var pointlist = [];

  @override
  void initState(){
    super.initState();
    _getCurrentUser();
    _getFavorite();

  }

  void _getCurrentUser() {
    loggedInUser = _auth.currentUser;
  }

  _refreshPage() async {
    var ret = await _firestore.collection('UrgentCases').where('id',isEqualTo: widget.urgentCase.id).get();

    var doc = ret.docs[0];
    widget.urgentCase.amountRaised = doc['amountRaised'];
    widget.urgentCase.active = doc['active'];

    setState(() {
    });
  }

  Future<void> _confirmDonationAmount() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(
              child: Text('Are You Sure?'.tr),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
            ),
            content: Text(
                "We see that you have entered a donation amount greater than \$999. We appreciate your generosity, but please confirm that this amount is correct to proceed.".tr),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async{
                          Navigator.pop(context);
                          await makePayment();


                        },
                        child: const Text('Yes'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('No'),
                      ),
                    ],
                  ),

                ],
              ),

            ],
          );
        });
  }
// get Favorite from firebase
  _getFavorite() async {
    await _firestore.collection("Favorite").doc(loggedInUser!.uid).get().then((value){
      setState(() {
        pointlist = List.from(value['favoriteList']);
      });
    });
  }

  _campaignDonateBody() {
    return ModalProgressHUD(
      inAsyncCall: showLoadingSpinner,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
            child: Padding(
              // Favorite button UI
              padding: const EdgeInsets.all(8.0),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                (_auth.currentUser?.email != null) ?
                Align(
                  alignment: Alignment.topRight,
                  child:IconButton(
                    icon: Icon(
                      pointlist.contains(widget.urgentCase.id.toString())? Icons.favorite: Icons.favorite_border,
                      color: pointlist.contains(widget.urgentCase.id.toString())? Colors.red:null,
                      size: 40,
                    ), onPressed: () async {
                    await updateFavorites(loggedInUser!.uid.toString(),widget.urgentCase.id.toString());
                    await _getFavorite();

                  },
                  ),) : Container(),
                SizedBox(
                    height: 100,
                    child: Image.asset('assets/DONAID_LOGO.png')
                ),
                Text(widget.urgentCase.title, style: TextStyle(fontSize: 25)),
                Text(widget.urgentCase.description, style: TextStyle(fontSize: 18),),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$'+f.format(widget.urgentCase.amountRaised),
                          style: const TextStyle(color: Colors.black, fontSize: 18),
                        ),
                        Text(
                          '\$'+f.format(widget.urgentCase.goalAmount),
                          style: const TextStyle(color: Colors.black, fontSize: 18),
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
                        value:
                        (widget.urgentCase.amountRaised / widget.urgentCase.goalAmount),
                        minHeight: 25,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: (widget.urgentCase.active == true && (widget.urgentCase.endDate).compareTo(Timestamp.now())>0)
                    ? Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              onChanged: (value) {
                                donationAmount = value.toString();
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'please_enter_a_valid_payment_amount'.tr;
                                }
                                else if(double.parse(value)<0.50){
                                  return 'please_provide_a_donation_minimum'.tr;
                                }
                                else {
                                  return null;
                                }
                              },
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                  label: Center(
                                    child: RichText(
                                        text: TextSpan(
                                          text: 'donation_amount'.tr,
                                          style: TextStyle(
                                              color: Colors.grey[600], fontSize: 20.0),
                                        )),
                                  ),
                                  border: const OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(32.0)),
                                  )),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Material(
                              elevation: 5.0,
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(32.0),
                              child: MaterialButton(
                                child:  Text(
                                  'donate'.tr,
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      showLoadingSpinner = true;
                                    });
                                    if(double.parse(donationAmount) > 999){
                                      //If donation is more than $1k, ask for confirmation
                                      _confirmDonationAmount();
                                    }
                                    else {
                                      //If donation is less than $1k, go to makePayment method
                                      await makePayment();
                                    }
                                    setState(() {
                                      showLoadingSpinner=false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ))
                  : Text('ugent_case_is_no_longer'.tr, style: TextStyle(fontSize: 18),),
                )
              ]),
            )),
      ),
    );
  }

  void createDonationDocument() async{
    //This method creates a document in the Donations collection to keep record of this donation
    final docRef = await _firestore.collection('Donations').add({});

    await _firestore.collection('Donations').doc(docRef.id).set({
      'id':docRef.id,
      'donorID': _auth.currentUser?.uid,
      'organizationID': widget.urgentCase.organizationID,
      'charityID': widget.urgentCase.id,
      'charityName':widget.urgentCase.title,
      'donationAmount': donationAmount,
      'donatedAt':Timestamp.now(),
      'charityType':'UrgentCases',
      'category':widget.urgentCase.category
    });

  }

  void updateUrgentCase() async{
    //This method updates the urgent case with this donation.
    if(widget.urgentCase.amountRaised+double.parse(donationAmount) >= widget.urgentCase.goalAmount){
      //If this donation makes the urgent case reach its goal amount, make the urgent case inactive
      await _firestore.collection('UrgentCases').doc(widget.urgentCase.id).update({
        'amountRaised': widget.urgentCase.amountRaised+double.parse(donationAmount),
        'active':false
      });
    }
    else{
      //If this donation did not make the urgent case reach its goal, simply add the donated amount
      // to the amountRaised field
      await _firestore.collection('UrgentCases').doc(widget.urgentCase.id).update({
        'amountRaised': widget.urgentCase.amountRaised+double.parse(donationAmount)
      });
    }

  }
  Future<void> makePayment() async {
    //This method calls the createPaymentIntent method and the calls the
    // method to create the payment sheet
    try {
      paymentIntentData =
      await createPaymentIntent(donationAmount, 'USD');
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentData!['client_secret'],
            applePay: true,
            googlePay: true,
            style: ThemeMode.dark,
            merchantCountryCode: 'US',
            merchantDisplayName: 'DONAID',
          ));

      print(paymentIntentData);
      await displayPaymentSheet();

    } catch (e) {
      print('Exception: ${e.toString()}');
    }
  }

  displayPaymentSheet() async {
    /*Displaying the payment sheet requires the client secret that is given from the payment intents
    * from the Stripe API (this is to keep track of this user's checkout session.*/
    try {
      await Stripe.instance.presentPaymentSheet(
        parameters: PresentPaymentSheetParameters(
          clientSecret: paymentIntentData!['client_secret'],
          confirmPayment: true,
        ),

      );

      setState(() {
        paymentIntentData = null;
      });
      //If the payment is successfully completed, show a message
      ScaffoldMessenger.of(context)
          .showSnackBar( SnackBar(content: Text('paid_successfully'.tr)));

      createDonationDocument();
      updateUrgentCase();
      await _refreshPage();

      showSimpleNotification(
        Text('Thank you!'),
        subtitle: Text('Your generosity is extremely appreciated!'),
        duration: Duration(seconds: 5),
        slideDismissDirection: DismissDirection.up,

      );

    }catch (e) {
      print('Stripe Exception: ${e.toString()}');

      //Show a message to indicate if the payment was cancelled
      ScaffoldMessenger.of(context)
          .showSnackBar( SnackBar(content: Text('payment_cancelled!'.tr)));

    }
  }

  createPaymentIntent(String amount, String currency) async {
    /*This method calls the node app to create a payment intent with the Stripe API.
    * The node app will then return the client secret that is needed to create the payment sheet*/
    try {
      final body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types':['card']
      };

      var response = await http.post(
          Uri.https('donaidmobileapp.herokuapp.com','/create-payment-intent'),
          body: jsonEncode(body),
          headers: {'Content-Type':'application/json'}
      );

      print(response.body);
      return jsonDecode(response.body);
    } catch (e) {
      print('Exception: ${e.toString()}');
    }
  }

  calculateAmount(String amount) {
    /*Stripe takes the payment amount as an integer. The integer that it takes is the payment amount
    * in pennies. so $1.50 will be sent to Stripe as 150.
    *
    * This method parses the donation amount to a double (so that we can handle fractional dollar donations). Then it multiplies
    * by 100 to convert to pennies. Then it does toInt to convert to integer so that Stripe will accept it. We return that integer dollar
    * amount as a string that is sent to the API*/
    final price = (double.parse(amount)*100).toInt();
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //doubt
        title: Text('donate'.tr + ' - ${widget.urgentCase.title}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: const DonorDrawer(),
      body: _campaignDonateBody(),
      bottomNavigationBar: DonorBottomNavigationBar(),
    );
  }
}
