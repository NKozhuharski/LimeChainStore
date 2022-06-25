// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Not invoked by the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
}

contract TechnoLimeStore is Ownable{
    struct Product {
       uint id;
       string name;
       uint quantity;
    }

    struct Purchase {
       address customer;
       uint blockNumber;
       string nameOfProduct;
       uint quantity;
    }

    uint private _id = 1;
    Purchase[] private history;
    Product[] private productList;
    address[] private customersAddresses;
    mapping(uint => bool) private existingId;
    mapping(string => bool) private existingProduct;
    mapping(address => bool) private buyersList;
    mapping(address => bool) private returnAddress;
    mapping(address => uint[]) private customerPurchases;

    modifier onlyBuyers {
        require(returnAddress[msg.sender], "You are not buyers listed.");
        _;
    }
    // // Log event to print the message details
    // event Log(address from, address to, string message);

    function isFirstBuyng(address customer, uint id) private view returns (bool) {  // Check whether it is the first time to buy the product.
        uint[] memory purchassesIds = customerPurchases[customer];
        for(uint i = 0; i < purchassesIds.length; i++) {
            if(purchassesIds[i] == id) {
                return false;
            }
        }
        return true;
    }

    function stringsEquals(string memory s1, string memory s2) private pure returns (bool) {  // Helper function, compare 2 strings.
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        if(l1 != b2.length) return false;
            for(uint256 i=0; i<l1; i++) {
                if(b1[i] != b2[i]) return false;
        }
        return true;
    }

    function addProductHelper(string memory productName, uint productQuantity) internal {  // Helper function to add products for ownable and not ownable reason.
        Product memory newProduct;
        if(existingProduct[productName]) {
            for(uint i = 0; i < productList.length; i++) {
                if(stringsEquals(productList[i].name, productName)) {
                productList[i].quantity += productQuantity;
                break; 
                }
            }
        } else {
            newProduct = Product({
                id: _id,
                name: productName,
                quantity: productQuantity
            });
            productList.push(newProduct);
            existingId[_id] = true;
            existingProduct[productName] = true;
            _id +=1;
           }
    }

    function add(string memory productName, uint productQuantity) public onlyOwner {  // Add product and quantity, Only owner.
        addProductHelper(productName, productQuantity);
    }

    function viewProducts() public view returns (Product[] memory) {  // Return all active product in the store.
    return productList;
    }

    function buy(uint productId, uint productQuantity) public {  //  Buy certain product only one time but not restriction for quantity, only to be available.
        require(existingId[productId] == true, "Don't have this id in this moment");

        if(!isFirstBuyng(msg.sender, productId)) {
            revert("This type of product has already been bought");
        }
    
        for (uint i = 0; i < productList.length; i++) {
            require(productList[i].quantity >= productQuantity, "Not enough quantity");

            if(productList[i].id == productId) {
                productList[i].quantity -= productQuantity;
                returnAddress[msg.sender] = true;
                    if (buyersList[msg.sender] == false) {
                    customersAddresses.push((msg.sender));
                    buyersList[msg.sender] = true;
                    }
                customerPurchases[msg.sender].push(productId);
                history.push(Purchase({
                    customer: msg.sender,
                    blockNumber: block.number,
                    nameOfProduct: productList[i].name,
                    quantity: productQuantity
                    }));
            }

            if(productList[i].quantity == 0 )  {
                delete existingId[productList[i].id];
                delete existingProduct[productList[i].name];
                productList[i] = productList[productList.length -1];
                productList.pop();
            } 
        }
    }

    function returnProduct(string memory productName) public onlyBuyers {  //  Return product: trying period 100 blocks time.
        bool isValid = false;
        for(uint i = 0; i < history.length; i++) {
            if(stringsEquals(history[i].nameOfProduct, productName)) isValid = true;
            if(history[i].blockNumber + 100 >= block.number && stringsEquals(history[i].nameOfProduct, productName)) {
                addProductHelper(productName, history[i].quantity);
                delete returnAddress[msg.sender];
            }
        }
        if(!isValid) {
            revert("You have entered a non-existent product");
        }
    }

    function viewCustomerAddresses () public view returns (address[] memory) {  //  Return everyone who has ever been a customer of the store. 
        return customersAddresses;
    }

}