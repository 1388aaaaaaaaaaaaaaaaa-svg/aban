/// Login state kept in memory for the current app session.
class AppState {
  // manager
  String? managerToken;
  String? managerBuildingName;

  // resident
  String? residentBuilding;
  String? residentUnit;
  String? residentCheck;

  // admin
  String? adminKey;

  void clear() {
    managerToken = null;
    managerBuildingName = null;
    residentBuilding = null;
    residentUnit = null;
    residentCheck = null;
    adminKey = null;
  }
}

final appState = AppState();
