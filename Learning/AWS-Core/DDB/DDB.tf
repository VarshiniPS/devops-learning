resource "aws_dynamodb_table" "test1" {
    name = "test1
    attribute {
    name = "CustomerID"
    type = "S"
  }

  attribute {
    name = "OrderID"
    type = "S"
  }
    hashkey = "custID"
    rangekey = "orderID"
    billing_mode = "PAY_PER_REQUEST"
}