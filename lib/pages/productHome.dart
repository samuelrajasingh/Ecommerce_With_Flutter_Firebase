import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_login_demo/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_login_demo/models/products.dart';
import 'dart:async';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';

class ProductPage extends StatefulWidget {
  ProductPage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Product> _productList;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pageController = PageController();

  StreamSubscription<Event> _onProductAddedSubscription;
  StreamSubscription<Event> _onProductChangedSubscription;

  Query _productQuery;

  int _currentIndex = 0;

  //bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();

    //_checkEmailVerification();

    _productList = new List();
    _productQuery = _database
        .reference()
        .child("product")
        .orderByChild("userId")
        .equalTo(widget.userId);
    _onProductAddedSubscription =
        _productQuery.onChildAdded.listen(onEntryAdded);
    _onProductChangedSubscription =
        _productQuery.onChildChanged.listen(onEntryChanged);
  }

  @override
  void dispose() {
    _onProductAddedSubscription.cancel();
    _onProductChangedSubscription.cancel();
    super.dispose();
  }

  onEntryChanged(Event event) {
    var oldEntry = _productList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      _productList[_productList.indexOf(oldEntry)] =
          Product.fromSnapshot(event.snapshot);
    });
  }

  onEntryAdded(Event event) {
    setState(() {
      _productList.add(Product.fromSnapshot(event.snapshot));
    });
  }

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  addNewProduct(String name, int price, int quantity) {
    if (name.length > 0) {
      Product product = new Product(widget.userId, name, price, quantity);
      _database.reference().child("product").push().set(product.toJson());
    }
  }

  deleteProduct(String productId, int index) {
    _database.reference().child("product").child(productId).remove().then((_) {
      print("Deleted $productId successful");
      setState(() {
        _productList.removeAt(index);
      });
    });
  }

  Widget showProductList() {
    if (_productList.length > 0) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _productList.length,
          itemBuilder: (BuildContext context, int index) {
            String productId = _productList[index].key;
            String name = _productList[index].name;
            int price = _productList[index].price;
            int quantity = _productList[index].quantity;
            //String userId = _productList[index].userId;
            return Dismissible(
              key: Key(productId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                deleteProduct(productId, index);
              },
              child: ListTile(
                leading: Image.asset('assets/flutter-icon.png'),
                title: Text(
                  name,
                  style: TextStyle(fontSize: 20.0),
                ),
                subtitle: Text(
                  'Rs :$price',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: Text(
                  'Quantity : Rs $quantity',
                ),
              ),
            );
          });
    } else {
      return Center(
          child: Text(
        " Welcome. Your product list is empty ",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 25.0),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Flutter Evaluation DEMO'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: signOut)
          ],
        ),
        body: SizedBox.expand(
          child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              children: [
                Container(child: showProductList()),
                FutureBuilder(
                    builder: (BuildContext context, AsyncSnapshot<Widget> jet) {
                  _nameController.clear();
                  _priceController.clear();
                  _quantityController.clear();
                  return SingleChildScrollView(
                                      child: AlertDialog(
                      content: new Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          new Padding(
                              padding: EdgeInsets.fromLTRB(44, 10, 44, 10),
                              child: new TextField(
                                controller: _nameController,
                                autofocus: true,
                                decoration: new InputDecoration(
                                  labelText: 'Enter Product Name',
                                ),
                              )),
                          new Padding(
                              padding: EdgeInsets.fromLTRB(44, 10, 44, 10),
                              child: TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  WhitelistingTextInputFormatter.digitsOnly
                                ],
                                decoration: new InputDecoration(
                                  labelText: 'Enter Product price',
                                ),
                              )),
                          new Padding(
                            padding: EdgeInsets.fromLTRB(44, 10, 44, 10),
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                WhitelistingTextInputFormatter.digitsOnly
                              ],
                              decoration: new InputDecoration(
                                labelText: 'Enter quantity',
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        // new FlatButton(
                        //     child: const Text('Cancel'),
                        //     onPressed: () {
                        //      // Navigator.pop(context);
                        //           debugPrint('cancel Build Context  --- >    $context');
                        //     }),
                        Padding(
                          padding:  EdgeInsets.fromLTRB(32, 0, 24, 8),
                          child: new RaisedButton(
                              color: Colors.blue,
                              child: const Text('Save'),
                              onPressed: () {
                                addNewProduct(
                                    _nameController.text.toString(),
                                    int.parse(_priceController.text.toString()),
                                    int.parse(_quantityController.text.toString()));
                                    debugPrint('save Build Context  --- >    $context /n Save success /n'  );
                                //Navigator.pop(context);
                              }),
                        )
                      ],
                    ),
                  );
                }),
              ]),
        ),
        bottomNavigationBar: BottomNavyBar(
          selectedIndex: _currentIndex,
          showElevation: true,
          itemCornerRadius: 20.0,
          onItemSelected: (index) => setState(() {
            _currentIndex = index;
debugPrint('Context-  -  > $context');
            _pageController.animateToPage(index,
                duration: Duration(milliseconds: 300), curve: Curves.ease);
          }),
          items: [
            BottomNavyBarItem(
              icon: Icon(Icons.apps),
              title: Text('Product List'),
              activeColor: Colors.blue,
            ),
            BottomNavyBarItem(
                icon: Icon(Icons.add_box),
                title: Text('Add to DB'),
                activeColor: Colors.blue),
          ],
        ));
  }
}
