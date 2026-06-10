import 'package:http/http.dart' as http;
import 'gas_client.dart';

class EmployeeProfile {
  final String employeeNumber;
  final String name;
  final String nationalId;
  final String birthDate;
  final String nameEn;
  final String birthPlace;
  final String gender;
  final String city;
  final String street;
  final String phone;
  final String mobile;
  final String maritalStatus;
  final String specialization;
  final String degree;
  final String workNature1;
  final String familyCount;
  final String userId;
  final String skills;
  final String responsibilities;
  final String workNature;
  final String riskLevel;
  final String effortFactor;
  final String workExperience;
  final String otherExperience;
  final String jobNumber;
  final String startDate;
  final String allowance;
  final String qualifications;
  final String msgStatus;
  final String bankAccount;
  final String ePriv;
  final String jobPos;
  final String repprsn;
  final String riskprs;

  const EmployeeProfile({
    required this.employeeNumber,
    required this.name,
    required this.nationalId,
    required this.birthDate,
    required this.nameEn,
    required this.birthPlace,
    required this.gender,
    required this.city,
    required this.street,
    required this.phone,
    required this.mobile,
    required this.maritalStatus,
    required this.specialization,
    required this.degree,
    required this.workNature1,
    required this.familyCount,
    required this.userId,
    required this.skills,
    required this.responsibilities,
    required this.workNature,
    required this.riskLevel,
    required this.effortFactor,
    required this.workExperience,
    required this.otherExperience,
    required this.jobNumber,
    required this.startDate,
    required this.allowance,
    required this.qualifications,
    required this.msgStatus,
    required this.bankAccount,
    required this.ePriv,
    required this.jobPos,
    required this.repprsn,
    required this.riskprs,
  });
}

class ProfileService {
  static const String _sheetId =
      '18Mcf2hWZTBialBUQ_tWPXbshFTInmDtSo-XbaLMWMSg';

  static Future<EmployeeProfile?> fetchProfile(String nationalId) async {
    try {
      final uri = Uri.https(
        'docs.google.com',
        '/spreadsheets/d/$_sheetId/gviz/tq',
        {'tqx': 'out:csv', 'sheet': 'data'},
      );
      final res =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return _parse(res.body, nationalId);
    } catch (_) {}
    return null;
  }

  static Future<bool> updateProfile(
      String nationalId, EmployeeProfile p) async {
    return GasClient.post({
      'action': 'update_data',
      'nationalId': nationalId,
      'row': [
        p.employeeNumber, p.name,     nationalId,       p.birthDate,
        p.nameEn,         p.birthPlace, p.gender,       p.city,
        p.street,         p.phone,      p.mobile,       p.maritalStatus,
        p.specialization, p.degree,     p.workNature1,  p.familyCount,
        p.userId,         p.skills,     p.responsibilities, p.workNature,
        p.riskLevel,      p.effortFactor, p.workExperience, p.otherExperience,
        p.jobNumber,      p.startDate,  p.allowance,    p.qualifications,
        p.msgStatus,      p.bankAccount, p.ePriv,       p.jobPos,
        p.repprsn,        p.riskprs,
      ],
    });
  }

  static EmployeeProfile? _parse(String body, String nationalId) {
    var raw = body;
    if (raw.startsWith('﻿')) raw = raw.substring(1);

    for (final line in raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)) {
      final c = _cols(line);
      if (c.length >= 3 && c[2] == nationalId) {
        String g(int i) => i < c.length ? c[i] : '';
        return EmployeeProfile(
          employeeNumber: g(0),
          name: g(1),
          nationalId: g(2),
          birthDate: g(3),
          nameEn: g(4),
          birthPlace: g(5),
          gender: g(6),
          city: g(7),
          street: g(8),
          phone: g(9),
          mobile: g(10),
          maritalStatus: g(11),
          specialization: g(12),
          degree: g(13),
          workNature1: g(14),
          familyCount: g(15),
          userId: g(16),
          skills: g(17),
          responsibilities: g(18),
          workNature: g(19),
          riskLevel: g(20),
          effortFactor: g(21),
          workExperience: g(22),
          otherExperience: g(23),
          jobNumber: g(24),
          startDate: g(25),
          allowance: g(26),
          qualifications: g(27),
          msgStatus: g(28),
          bankAccount: g(29),
          ePriv: g(30),
          jobPos: g(31),
          repprsn: g(32),
          riskprs: g(33),
        );
      }
    }
    return null;
  }

  static List<String> _cols(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool q = false;
    for (final ch in line.runes) {
      final c = String.fromCharCode(ch);
      if (c == '"') {
        q = !q;
      } else if (c == ',' && !q) {
        result.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString().trim());
    return result;
  }
}
