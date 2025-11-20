class Category {

  final String id;
  String _name;
  final bool isDefault;

  Category({
    required this.id,
    required name,
    this.isDefault = false,
  }): _name = name;

  //this method might not be used
  void setName(String newName){
    this._name = newName;
  }

  String getName(){
    return this._name;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }

Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
    };
  }
}