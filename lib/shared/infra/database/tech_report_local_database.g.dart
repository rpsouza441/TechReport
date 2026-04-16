// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tech_report_local_database.dart';

// ignore_for_file: type=lint
class $TecnicoLocalsTable extends TecnicoLocals
    with TableInfo<$TecnicoLocalsTable, TecnicoLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TecnicoLocalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telefoneMeta = const VerificationMeta(
    'telefone',
  );
  @override
  late final GeneratedColumn<String> telefone = GeneratedColumn<String>(
    'telefone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _empresaNomeMeta = const VerificationMeta(
    'empresaNome',
  );
  @override
  late final GeneratedColumn<String> empresaNome = GeneratedColumn<String>(
    'empresa_nome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assinaturaPadraoRefMeta =
      const VerificationMeta('assinaturaPadraoRef');
  @override
  late final GeneratedColumn<String> assinaturaPadraoRef =
      GeneratedColumn<String>(
        'assinatura_padrao_ref',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _pinConfiguredMeta = const VerificationMeta(
    'pinConfigured',
  );
  @override
  late final GeneratedColumn<bool> pinConfigured = GeneratedColumn<bool>(
    'pin_configured',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pin_configured" IN (0, 1))',
    ),
  );
  static const VerificationMeta _biometriaHabilitadaMeta =
      const VerificationMeta('biometriaHabilitada');
  @override
  late final GeneratedColumn<bool> biometriaHabilitada = GeneratedColumn<bool>(
    'biometria_habilitada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("biometria_habilitada" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nome,
    email,
    telefone,
    empresaNome,
    assinaturaPadraoRef,
    pinConfigured,
    biometriaHabilitada,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tecnico_locals';
  @override
  VerificationContext validateIntegrity(
    Insertable<TecnicoLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('telefone')) {
      context.handle(
        _telefoneMeta,
        telefone.isAcceptableOrUnknown(data['telefone']!, _telefoneMeta),
      );
    }
    if (data.containsKey('empresa_nome')) {
      context.handle(
        _empresaNomeMeta,
        empresaNome.isAcceptableOrUnknown(
          data['empresa_nome']!,
          _empresaNomeMeta,
        ),
      );
    }
    if (data.containsKey('assinatura_padrao_ref')) {
      context.handle(
        _assinaturaPadraoRefMeta,
        assinaturaPadraoRef.isAcceptableOrUnknown(
          data['assinatura_padrao_ref']!,
          _assinaturaPadraoRefMeta,
        ),
      );
    }
    if (data.containsKey('pin_configured')) {
      context.handle(
        _pinConfiguredMeta,
        pinConfigured.isAcceptableOrUnknown(
          data['pin_configured']!,
          _pinConfiguredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pinConfiguredMeta);
    }
    if (data.containsKey('biometria_habilitada')) {
      context.handle(
        _biometriaHabilitadaMeta,
        biometriaHabilitada.isAcceptableOrUnknown(
          data['biometria_habilitada']!,
          _biometriaHabilitadaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_biometriaHabilitadaMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TecnicoLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TecnicoLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      telefone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefone'],
      ),
      empresaNome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_nome'],
      ),
      assinaturaPadraoRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assinatura_padrao_ref'],
      ),
      pinConfigured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pin_configured'],
      )!,
      biometriaHabilitada: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}biometria_habilitada'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TecnicoLocalsTable createAlias(String alias) {
    return $TecnicoLocalsTable(attachedDatabase, alias);
  }
}

class TecnicoLocal extends DataClass implements Insertable<TecnicoLocal> {
  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String? empresaNome;
  final String? assinaturaPadraoRef;
  final bool pinConfigured;
  final bool biometriaHabilitada;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TecnicoLocal({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.empresaNome,
    this.assinaturaPadraoRef,
    required this.pinConfigured,
    required this.biometriaHabilitada,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || telefone != null) {
      map['telefone'] = Variable<String>(telefone);
    }
    if (!nullToAbsent || empresaNome != null) {
      map['empresa_nome'] = Variable<String>(empresaNome);
    }
    if (!nullToAbsent || assinaturaPadraoRef != null) {
      map['assinatura_padrao_ref'] = Variable<String>(assinaturaPadraoRef);
    }
    map['pin_configured'] = Variable<bool>(pinConfigured);
    map['biometria_habilitada'] = Variable<bool>(biometriaHabilitada);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TecnicoLocalsCompanion toCompanion(bool nullToAbsent) {
    return TecnicoLocalsCompanion(
      id: Value(id),
      nome: Value(nome),
      email: Value(email),
      telefone: telefone == null && nullToAbsent
          ? const Value.absent()
          : Value(telefone),
      empresaNome: empresaNome == null && nullToAbsent
          ? const Value.absent()
          : Value(empresaNome),
      assinaturaPadraoRef: assinaturaPadraoRef == null && nullToAbsent
          ? const Value.absent()
          : Value(assinaturaPadraoRef),
      pinConfigured: Value(pinConfigured),
      biometriaHabilitada: Value(biometriaHabilitada),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TecnicoLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TecnicoLocal(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      email: serializer.fromJson<String>(json['email']),
      telefone: serializer.fromJson<String?>(json['telefone']),
      empresaNome: serializer.fromJson<String?>(json['empresaNome']),
      assinaturaPadraoRef: serializer.fromJson<String?>(
        json['assinaturaPadraoRef'],
      ),
      pinConfigured: serializer.fromJson<bool>(json['pinConfigured']),
      biometriaHabilitada: serializer.fromJson<bool>(
        json['biometriaHabilitada'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'email': serializer.toJson<String>(email),
      'telefone': serializer.toJson<String?>(telefone),
      'empresaNome': serializer.toJson<String?>(empresaNome),
      'assinaturaPadraoRef': serializer.toJson<String?>(assinaturaPadraoRef),
      'pinConfigured': serializer.toJson<bool>(pinConfigured),
      'biometriaHabilitada': serializer.toJson<bool>(biometriaHabilitada),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TecnicoLocal copyWith({
    String? id,
    String? nome,
    String? email,
    Value<String?> telefone = const Value.absent(),
    Value<String?> empresaNome = const Value.absent(),
    Value<String?> assinaturaPadraoRef = const Value.absent(),
    bool? pinConfigured,
    bool? biometriaHabilitada,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TecnicoLocal(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    email: email ?? this.email,
    telefone: telefone.present ? telefone.value : this.telefone,
    empresaNome: empresaNome.present ? empresaNome.value : this.empresaNome,
    assinaturaPadraoRef: assinaturaPadraoRef.present
        ? assinaturaPadraoRef.value
        : this.assinaturaPadraoRef,
    pinConfigured: pinConfigured ?? this.pinConfigured,
    biometriaHabilitada: biometriaHabilitada ?? this.biometriaHabilitada,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TecnicoLocal copyWithCompanion(TecnicoLocalsCompanion data) {
    return TecnicoLocal(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      email: data.email.present ? data.email.value : this.email,
      telefone: data.telefone.present ? data.telefone.value : this.telefone,
      empresaNome: data.empresaNome.present
          ? data.empresaNome.value
          : this.empresaNome,
      assinaturaPadraoRef: data.assinaturaPadraoRef.present
          ? data.assinaturaPadraoRef.value
          : this.assinaturaPadraoRef,
      pinConfigured: data.pinConfigured.present
          ? data.pinConfigured.value
          : this.pinConfigured,
      biometriaHabilitada: data.biometriaHabilitada.present
          ? data.biometriaHabilitada.value
          : this.biometriaHabilitada,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TecnicoLocal(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('telefone: $telefone, ')
          ..write('empresaNome: $empresaNome, ')
          ..write('assinaturaPadraoRef: $assinaturaPadraoRef, ')
          ..write('pinConfigured: $pinConfigured, ')
          ..write('biometriaHabilitada: $biometriaHabilitada, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nome,
    email,
    telefone,
    empresaNome,
    assinaturaPadraoRef,
    pinConfigured,
    biometriaHabilitada,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TecnicoLocal &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.email == this.email &&
          other.telefone == this.telefone &&
          other.empresaNome == this.empresaNome &&
          other.assinaturaPadraoRef == this.assinaturaPadraoRef &&
          other.pinConfigured == this.pinConfigured &&
          other.biometriaHabilitada == this.biometriaHabilitada &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TecnicoLocalsCompanion extends UpdateCompanion<TecnicoLocal> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String> email;
  final Value<String?> telefone;
  final Value<String?> empresaNome;
  final Value<String?> assinaturaPadraoRef;
  final Value<bool> pinConfigured;
  final Value<bool> biometriaHabilitada;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TecnicoLocalsCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.email = const Value.absent(),
    this.telefone = const Value.absent(),
    this.empresaNome = const Value.absent(),
    this.assinaturaPadraoRef = const Value.absent(),
    this.pinConfigured = const Value.absent(),
    this.biometriaHabilitada = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TecnicoLocalsCompanion.insert({
    required String id,
    required String nome,
    required String email,
    this.telefone = const Value.absent(),
    this.empresaNome = const Value.absent(),
    this.assinaturaPadraoRef = const Value.absent(),
    required bool pinConfigured,
    required bool biometriaHabilitada,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome),
       email = Value(email),
       pinConfigured = Value(pinConfigured),
       biometriaHabilitada = Value(biometriaHabilitada),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TecnicoLocal> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? email,
    Expression<String>? telefone,
    Expression<String>? empresaNome,
    Expression<String>? assinaturaPadraoRef,
    Expression<bool>? pinConfigured,
    Expression<bool>? biometriaHabilitada,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (email != null) 'email': email,
      if (telefone != null) 'telefone': telefone,
      if (empresaNome != null) 'empresa_nome': empresaNome,
      if (assinaturaPadraoRef != null)
        'assinatura_padrao_ref': assinaturaPadraoRef,
      if (pinConfigured != null) 'pin_configured': pinConfigured,
      if (biometriaHabilitada != null)
        'biometria_habilitada': biometriaHabilitada,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TecnicoLocalsCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<String>? email,
    Value<String?>? telefone,
    Value<String?>? empresaNome,
    Value<String?>? assinaturaPadraoRef,
    Value<bool>? pinConfigured,
    Value<bool>? biometriaHabilitada,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TecnicoLocalsCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      empresaNome: empresaNome ?? this.empresaNome,
      assinaturaPadraoRef: assinaturaPadraoRef ?? this.assinaturaPadraoRef,
      pinConfigured: pinConfigured ?? this.pinConfigured,
      biometriaHabilitada: biometriaHabilitada ?? this.biometriaHabilitada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (telefone.present) {
      map['telefone'] = Variable<String>(telefone.value);
    }
    if (empresaNome.present) {
      map['empresa_nome'] = Variable<String>(empresaNome.value);
    }
    if (assinaturaPadraoRef.present) {
      map['assinatura_padrao_ref'] = Variable<String>(
        assinaturaPadraoRef.value,
      );
    }
    if (pinConfigured.present) {
      map['pin_configured'] = Variable<bool>(pinConfigured.value);
    }
    if (biometriaHabilitada.present) {
      map['biometria_habilitada'] = Variable<bool>(biometriaHabilitada.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TecnicoLocalsCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('telefone: $telefone, ')
          ..write('empresaNome: $empresaNome, ')
          ..write('assinaturaPadraoRef: $assinaturaPadraoRef, ')
          ..write('pinConfigured: $pinConfigured, ')
          ..write('biometriaHabilitada: $biometriaHabilitada, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessaoLocalsTable extends SessaoLocals
    with TableInfo<$SessaoLocalsTable, SessaoLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessaoLocalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tecnicoLocalIdMeta = const VerificationMeta(
    'tecnicoLocalId',
  );
  @override
  late final GeneratedColumn<String> tecnicoLocalId = GeneratedColumn<String>(
    'tecnico_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinConfiguredMeta = const VerificationMeta(
    'pinConfigured',
  );
  @override
  late final GeneratedColumn<bool> pinConfigured = GeneratedColumn<bool>(
    'pin_configured',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pin_configured" IN (0, 1))',
    ),
  );
  static const VerificationMeta _biometriaDisponivelMeta =
      const VerificationMeta('biometriaDisponivel');
  @override
  late final GeneratedColumn<bool> biometriaDisponivel = GeneratedColumn<bool>(
    'biometria_disponivel',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("biometria_disponivel" IN (0, 1))',
    ),
  );
  static const VerificationMeta _biometriaHabilitadaMeta =
      const VerificationMeta('biometriaHabilitada');
  @override
  late final GeneratedColumn<bool> biometriaHabilitada = GeneratedColumn<bool>(
    'biometria_habilitada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("biometria_habilitada" IN (0, 1))',
    ),
  );
  static const VerificationMeta _onboardingConcluidoMeta =
      const VerificationMeta('onboardingConcluido');
  @override
  late final GeneratedColumn<bool> onboardingConcluido = GeneratedColumn<bool>(
    'onboarding_concluido',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_concluido" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastUnlockedAtMeta = const VerificationMeta(
    'lastUnlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUnlockedAt =
      GeneratedColumn<DateTime>(
        'last_unlocked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mode,
    tecnicoLocalId,
    status,
    pinConfigured,
    biometriaDisponivel,
    biometriaHabilitada,
    onboardingConcluido,
    lastUnlockedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessao_locals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessaoLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('tecnico_local_id')) {
      context.handle(
        _tecnicoLocalIdMeta,
        tecnicoLocalId.isAcceptableOrUnknown(
          data['tecnico_local_id']!,
          _tecnicoLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tecnicoLocalIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('pin_configured')) {
      context.handle(
        _pinConfiguredMeta,
        pinConfigured.isAcceptableOrUnknown(
          data['pin_configured']!,
          _pinConfiguredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pinConfiguredMeta);
    }
    if (data.containsKey('biometria_disponivel')) {
      context.handle(
        _biometriaDisponivelMeta,
        biometriaDisponivel.isAcceptableOrUnknown(
          data['biometria_disponivel']!,
          _biometriaDisponivelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_biometriaDisponivelMeta);
    }
    if (data.containsKey('biometria_habilitada')) {
      context.handle(
        _biometriaHabilitadaMeta,
        biometriaHabilitada.isAcceptableOrUnknown(
          data['biometria_habilitada']!,
          _biometriaHabilitadaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_biometriaHabilitadaMeta);
    }
    if (data.containsKey('onboarding_concluido')) {
      context.handle(
        _onboardingConcluidoMeta,
        onboardingConcluido.isAcceptableOrUnknown(
          data['onboarding_concluido']!,
          _onboardingConcluidoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_onboardingConcluidoMeta);
    }
    if (data.containsKey('last_unlocked_at')) {
      context.handle(
        _lastUnlockedAtMeta,
        lastUnlockedAt.isAcceptableOrUnknown(
          data['last_unlocked_at']!,
          _lastUnlockedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessaoLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessaoLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      tecnicoLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tecnico_local_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      pinConfigured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pin_configured'],
      )!,
      biometriaDisponivel: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}biometria_disponivel'],
      )!,
      biometriaHabilitada: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}biometria_habilitada'],
      )!,
      onboardingConcluido: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_concluido'],
      )!,
      lastUnlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_unlocked_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SessaoLocalsTable createAlias(String alias) {
    return $SessaoLocalsTable(attachedDatabase, alias);
  }
}

class SessaoLocal extends DataClass implements Insertable<SessaoLocal> {
  final String id;
  final String mode;
  final String tecnicoLocalId;
  final String status;
  final bool pinConfigured;
  final bool biometriaDisponivel;
  final bool biometriaHabilitada;
  final bool onboardingConcluido;
  final DateTime? lastUnlockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SessaoLocal({
    required this.id,
    required this.mode,
    required this.tecnicoLocalId,
    required this.status,
    required this.pinConfigured,
    required this.biometriaDisponivel,
    required this.biometriaHabilitada,
    required this.onboardingConcluido,
    this.lastUnlockedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mode'] = Variable<String>(mode);
    map['tecnico_local_id'] = Variable<String>(tecnicoLocalId);
    map['status'] = Variable<String>(status);
    map['pin_configured'] = Variable<bool>(pinConfigured);
    map['biometria_disponivel'] = Variable<bool>(biometriaDisponivel);
    map['biometria_habilitada'] = Variable<bool>(biometriaHabilitada);
    map['onboarding_concluido'] = Variable<bool>(onboardingConcluido);
    if (!nullToAbsent || lastUnlockedAt != null) {
      map['last_unlocked_at'] = Variable<DateTime>(lastUnlockedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessaoLocalsCompanion toCompanion(bool nullToAbsent) {
    return SessaoLocalsCompanion(
      id: Value(id),
      mode: Value(mode),
      tecnicoLocalId: Value(tecnicoLocalId),
      status: Value(status),
      pinConfigured: Value(pinConfigured),
      biometriaDisponivel: Value(biometriaDisponivel),
      biometriaHabilitada: Value(biometriaHabilitada),
      onboardingConcluido: Value(onboardingConcluido),
      lastUnlockedAt: lastUnlockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUnlockedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SessaoLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessaoLocal(
      id: serializer.fromJson<String>(json['id']),
      mode: serializer.fromJson<String>(json['mode']),
      tecnicoLocalId: serializer.fromJson<String>(json['tecnicoLocalId']),
      status: serializer.fromJson<String>(json['status']),
      pinConfigured: serializer.fromJson<bool>(json['pinConfigured']),
      biometriaDisponivel: serializer.fromJson<bool>(
        json['biometriaDisponivel'],
      ),
      biometriaHabilitada: serializer.fromJson<bool>(
        json['biometriaHabilitada'],
      ),
      onboardingConcluido: serializer.fromJson<bool>(
        json['onboardingConcluido'],
      ),
      lastUnlockedAt: serializer.fromJson<DateTime?>(json['lastUnlockedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mode': serializer.toJson<String>(mode),
      'tecnicoLocalId': serializer.toJson<String>(tecnicoLocalId),
      'status': serializer.toJson<String>(status),
      'pinConfigured': serializer.toJson<bool>(pinConfigured),
      'biometriaDisponivel': serializer.toJson<bool>(biometriaDisponivel),
      'biometriaHabilitada': serializer.toJson<bool>(biometriaHabilitada),
      'onboardingConcluido': serializer.toJson<bool>(onboardingConcluido),
      'lastUnlockedAt': serializer.toJson<DateTime?>(lastUnlockedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SessaoLocal copyWith({
    String? id,
    String? mode,
    String? tecnicoLocalId,
    String? status,
    bool? pinConfigured,
    bool? biometriaDisponivel,
    bool? biometriaHabilitada,
    bool? onboardingConcluido,
    Value<DateTime?> lastUnlockedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SessaoLocal(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    tecnicoLocalId: tecnicoLocalId ?? this.tecnicoLocalId,
    status: status ?? this.status,
    pinConfigured: pinConfigured ?? this.pinConfigured,
    biometriaDisponivel: biometriaDisponivel ?? this.biometriaDisponivel,
    biometriaHabilitada: biometriaHabilitada ?? this.biometriaHabilitada,
    onboardingConcluido: onboardingConcluido ?? this.onboardingConcluido,
    lastUnlockedAt: lastUnlockedAt.present
        ? lastUnlockedAt.value
        : this.lastUnlockedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SessaoLocal copyWithCompanion(SessaoLocalsCompanion data) {
    return SessaoLocal(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      tecnicoLocalId: data.tecnicoLocalId.present
          ? data.tecnicoLocalId.value
          : this.tecnicoLocalId,
      status: data.status.present ? data.status.value : this.status,
      pinConfigured: data.pinConfigured.present
          ? data.pinConfigured.value
          : this.pinConfigured,
      biometriaDisponivel: data.biometriaDisponivel.present
          ? data.biometriaDisponivel.value
          : this.biometriaDisponivel,
      biometriaHabilitada: data.biometriaHabilitada.present
          ? data.biometriaHabilitada.value
          : this.biometriaHabilitada,
      onboardingConcluido: data.onboardingConcluido.present
          ? data.onboardingConcluido.value
          : this.onboardingConcluido,
      lastUnlockedAt: data.lastUnlockedAt.present
          ? data.lastUnlockedAt.value
          : this.lastUnlockedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessaoLocal(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('tecnicoLocalId: $tecnicoLocalId, ')
          ..write('status: $status, ')
          ..write('pinConfigured: $pinConfigured, ')
          ..write('biometriaDisponivel: $biometriaDisponivel, ')
          ..write('biometriaHabilitada: $biometriaHabilitada, ')
          ..write('onboardingConcluido: $onboardingConcluido, ')
          ..write('lastUnlockedAt: $lastUnlockedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    tecnicoLocalId,
    status,
    pinConfigured,
    biometriaDisponivel,
    biometriaHabilitada,
    onboardingConcluido,
    lastUnlockedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessaoLocal &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.tecnicoLocalId == this.tecnicoLocalId &&
          other.status == this.status &&
          other.pinConfigured == this.pinConfigured &&
          other.biometriaDisponivel == this.biometriaDisponivel &&
          other.biometriaHabilitada == this.biometriaHabilitada &&
          other.onboardingConcluido == this.onboardingConcluido &&
          other.lastUnlockedAt == this.lastUnlockedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SessaoLocalsCompanion extends UpdateCompanion<SessaoLocal> {
  final Value<String> id;
  final Value<String> mode;
  final Value<String> tecnicoLocalId;
  final Value<String> status;
  final Value<bool> pinConfigured;
  final Value<bool> biometriaDisponivel;
  final Value<bool> biometriaHabilitada;
  final Value<bool> onboardingConcluido;
  final Value<DateTime?> lastUnlockedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SessaoLocalsCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.tecnicoLocalId = const Value.absent(),
    this.status = const Value.absent(),
    this.pinConfigured = const Value.absent(),
    this.biometriaDisponivel = const Value.absent(),
    this.biometriaHabilitada = const Value.absent(),
    this.onboardingConcluido = const Value.absent(),
    this.lastUnlockedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessaoLocalsCompanion.insert({
    required String id,
    required String mode,
    required String tecnicoLocalId,
    required String status,
    required bool pinConfigured,
    required bool biometriaDisponivel,
    required bool biometriaHabilitada,
    required bool onboardingConcluido,
    this.lastUnlockedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mode = Value(mode),
       tecnicoLocalId = Value(tecnicoLocalId),
       status = Value(status),
       pinConfigured = Value(pinConfigured),
       biometriaDisponivel = Value(biometriaDisponivel),
       biometriaHabilitada = Value(biometriaHabilitada),
       onboardingConcluido = Value(onboardingConcluido),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SessaoLocal> custom({
    Expression<String>? id,
    Expression<String>? mode,
    Expression<String>? tecnicoLocalId,
    Expression<String>? status,
    Expression<bool>? pinConfigured,
    Expression<bool>? biometriaDisponivel,
    Expression<bool>? biometriaHabilitada,
    Expression<bool>? onboardingConcluido,
    Expression<DateTime>? lastUnlockedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (tecnicoLocalId != null) 'tecnico_local_id': tecnicoLocalId,
      if (status != null) 'status': status,
      if (pinConfigured != null) 'pin_configured': pinConfigured,
      if (biometriaDisponivel != null)
        'biometria_disponivel': biometriaDisponivel,
      if (biometriaHabilitada != null)
        'biometria_habilitada': biometriaHabilitada,
      if (onboardingConcluido != null)
        'onboarding_concluido': onboardingConcluido,
      if (lastUnlockedAt != null) 'last_unlocked_at': lastUnlockedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessaoLocalsCompanion copyWith({
    Value<String>? id,
    Value<String>? mode,
    Value<String>? tecnicoLocalId,
    Value<String>? status,
    Value<bool>? pinConfigured,
    Value<bool>? biometriaDisponivel,
    Value<bool>? biometriaHabilitada,
    Value<bool>? onboardingConcluido,
    Value<DateTime?>? lastUnlockedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SessaoLocalsCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      tecnicoLocalId: tecnicoLocalId ?? this.tecnicoLocalId,
      status: status ?? this.status,
      pinConfigured: pinConfigured ?? this.pinConfigured,
      biometriaDisponivel: biometriaDisponivel ?? this.biometriaDisponivel,
      biometriaHabilitada: biometriaHabilitada ?? this.biometriaHabilitada,
      onboardingConcluido: onboardingConcluido ?? this.onboardingConcluido,
      lastUnlockedAt: lastUnlockedAt ?? this.lastUnlockedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (tecnicoLocalId.present) {
      map['tecnico_local_id'] = Variable<String>(tecnicoLocalId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pinConfigured.present) {
      map['pin_configured'] = Variable<bool>(pinConfigured.value);
    }
    if (biometriaDisponivel.present) {
      map['biometria_disponivel'] = Variable<bool>(biometriaDisponivel.value);
    }
    if (biometriaHabilitada.present) {
      map['biometria_habilitada'] = Variable<bool>(biometriaHabilitada.value);
    }
    if (onboardingConcluido.present) {
      map['onboarding_concluido'] = Variable<bool>(onboardingConcluido.value);
    }
    if (lastUnlockedAt.present) {
      map['last_unlocked_at'] = Variable<DateTime>(lastUnlockedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessaoLocalsCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('tecnicoLocalId: $tecnicoLocalId, ')
          ..write('status: $status, ')
          ..write('pinConfigured: $pinConfigured, ')
          ..write('biometriaDisponivel: $biometriaDisponivel, ')
          ..write('biometriaHabilitada: $biometriaHabilitada, ')
          ..write('onboardingConcluido: $onboardingConcluido, ')
          ..write('lastUnlockedAt: $lastUnlockedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RatsTable extends Rats with TableInfo<$RatsTable, Rat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerTypeMeta = const VerificationMeta(
    'ownerType',
  );
  @override
  late final GeneratedColumn<String> ownerType = GeneratedColumn<String>(
    'owner_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroMeta = const VerificationMeta('numero');
  @override
  late final GeneratedColumn<String> numero = GeneratedColumn<String>(
    'numero',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clienteNomeMeta = const VerificationMeta(
    'clienteNome',
  );
  @override
  late final GeneratedColumn<String> clienteNome = GeneratedColumn<String>(
    'cliente_nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    authorId,
    ownerType,
    numero,
    clienteNome,
    descricao,
    status,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Rat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('owner_type')) {
      context.handle(
        _ownerTypeMeta,
        ownerType.isAcceptableOrUnknown(data['owner_type']!, _ownerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerTypeMeta);
    }
    if (data.containsKey('numero')) {
      context.handle(
        _numeroMeta,
        numero.isAcceptableOrUnknown(data['numero']!, _numeroMeta),
      );
    } else if (isInserting) {
      context.missing(_numeroMeta);
    }
    if (data.containsKey('cliente_nome')) {
      context.handle(
        _clienteNomeMeta,
        clienteNome.isAcceptableOrUnknown(
          data['cliente_nome']!,
          _clienteNomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clienteNomeMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Rat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Rat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      ownerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_type'],
      )!,
      numero: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero'],
      )!,
      clienteNome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cliente_nome'],
      )!,
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $RatsTable createAlias(String alias) {
    return $RatsTable(attachedDatabase, alias);
  }
}

class Rat extends DataClass implements Insertable<Rat> {
  final String id;
  final String authorId;
  final String ownerType;
  final String numero;
  final String clienteNome;
  final String descricao;
  final String status;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Rat({
    required this.id,
    required this.authorId,
    required this.ownerType,
    required this.numero,
    required this.clienteNome,
    required this.descricao,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['author_id'] = Variable<String>(authorId);
    map['owner_type'] = Variable<String>(ownerType);
    map['numero'] = Variable<String>(numero);
    map['cliente_nome'] = Variable<String>(clienteNome);
    map['descricao'] = Variable<String>(descricao);
    map['status'] = Variable<String>(status);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  RatsCompanion toCompanion(bool nullToAbsent) {
    return RatsCompanion(
      id: Value(id),
      authorId: Value(authorId),
      ownerType: Value(ownerType),
      numero: Value(numero),
      clienteNome: Value(clienteNome),
      descricao: Value(descricao),
      status: Value(status),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Rat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Rat(
      id: serializer.fromJson<String>(json['id']),
      authorId: serializer.fromJson<String>(json['authorId']),
      ownerType: serializer.fromJson<String>(json['ownerType']),
      numero: serializer.fromJson<String>(json['numero']),
      clienteNome: serializer.fromJson<String>(json['clienteNome']),
      descricao: serializer.fromJson<String>(json['descricao']),
      status: serializer.fromJson<String>(json['status']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'authorId': serializer.toJson<String>(authorId),
      'ownerType': serializer.toJson<String>(ownerType),
      'numero': serializer.toJson<String>(numero),
      'clienteNome': serializer.toJson<String>(clienteNome),
      'descricao': serializer.toJson<String>(descricao),
      'status': serializer.toJson<String>(status),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Rat copyWith({
    String? id,
    String? authorId,
    String? ownerType,
    String? numero,
    String? clienteNome,
    String? descricao,
    String? status,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Rat(
    id: id ?? this.id,
    authorId: authorId ?? this.authorId,
    ownerType: ownerType ?? this.ownerType,
    numero: numero ?? this.numero,
    clienteNome: clienteNome ?? this.clienteNome,
    descricao: descricao ?? this.descricao,
    status: status ?? this.status,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Rat copyWithCompanion(RatsCompanion data) {
    return Rat(
      id: data.id.present ? data.id.value : this.id,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      numero: data.numero.present ? data.numero.value : this.numero,
      clienteNome: data.clienteNome.present
          ? data.clienteNome.value
          : this.clienteNome,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      status: data.status.present ? data.status.value : this.status,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Rat(')
          ..write('id: $id, ')
          ..write('authorId: $authorId, ')
          ..write('ownerType: $ownerType, ')
          ..write('numero: $numero, ')
          ..write('clienteNome: $clienteNome, ')
          ..write('descricao: $descricao, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    authorId,
    ownerType,
    numero,
    clienteNome,
    descricao,
    status,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rat &&
          other.id == this.id &&
          other.authorId == this.authorId &&
          other.ownerType == this.ownerType &&
          other.numero == this.numero &&
          other.clienteNome == this.clienteNome &&
          other.descricao == this.descricao &&
          other.status == this.status &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RatsCompanion extends UpdateCompanion<Rat> {
  final Value<String> id;
  final Value<String> authorId;
  final Value<String> ownerType;
  final Value<String> numero;
  final Value<String> clienteNome;
  final Value<String> descricao;
  final Value<String> status;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const RatsCompanion({
    this.id = const Value.absent(),
    this.authorId = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.numero = const Value.absent(),
    this.clienteNome = const Value.absent(),
    this.descricao = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatsCompanion.insert({
    required String id,
    required String authorId,
    required String ownerType,
    required String numero,
    required String clienteNome,
    required String descricao,
    required String status,
    required String syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       authorId = Value(authorId),
       ownerType = Value(ownerType),
       numero = Value(numero),
       clienteNome = Value(clienteNome),
       descricao = Value(descricao),
       status = Value(status),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Rat> custom({
    Expression<String>? id,
    Expression<String>? authorId,
    Expression<String>? ownerType,
    Expression<String>? numero,
    Expression<String>? clienteNome,
    Expression<String>? descricao,
    Expression<String>? status,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (ownerType != null) 'owner_type': ownerType,
      if (numero != null) 'numero': numero,
      if (clienteNome != null) 'cliente_nome': clienteNome,
      if (descricao != null) 'descricao': descricao,
      if (status != null) 'status': status,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatsCompanion copyWith({
    Value<String>? id,
    Value<String>? authorId,
    Value<String>? ownerType,
    Value<String>? numero,
    Value<String>? clienteNome,
    Value<String>? descricao,
    Value<String>? status,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return RatsCompanion(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      ownerType: ownerType ?? this.ownerType,
      numero: numero ?? this.numero,
      clienteNome: clienteNome ?? this.clienteNome,
      descricao: descricao ?? this.descricao,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (ownerType.present) {
      map['owner_type'] = Variable<String>(ownerType.value);
    }
    if (numero.present) {
      map['numero'] = Variable<String>(numero.value);
    }
    if (clienteNome.present) {
      map['cliente_nome'] = Variable<String>(clienteNome.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatsCompanion(')
          ..write('id: $id, ')
          ..write('authorId: $authorId, ')
          ..write('ownerType: $ownerType, ')
          ..write('numero: $numero, ')
          ..write('clienteNome: $clienteNome, ')
          ..write('descricao: $descricao, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssinaturasTable extends Assinaturas
    with TableInfo<$AssinaturasTable, Assinatura> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssinaturasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratIdMeta = const VerificationMeta('ratId');
  @override
  late final GeneratedColumn<String> ratId = GeneratedColumn<String>(
    'rat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageModeMeta = const VerificationMeta(
    'storageMode',
  );
  @override
  late final GeneratedColumn<String> storageMode = GeneratedColumn<String>(
    'storage_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetRefMeta = const VerificationMeta(
    'assetRef',
  );
  @override
  late final GeneratedColumn<String> assetRef = GeneratedColumn<String>(
    'asset_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ratId,
    storageMode,
    assetRef,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assinaturas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Assinatura> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rat_id')) {
      context.handle(
        _ratIdMeta,
        ratId.isAcceptableOrUnknown(data['rat_id']!, _ratIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ratIdMeta);
    }
    if (data.containsKey('storage_mode')) {
      context.handle(
        _storageModeMeta,
        storageMode.isAcceptableOrUnknown(
          data['storage_mode']!,
          _storageModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storageModeMeta);
    }
    if (data.containsKey('asset_ref')) {
      context.handle(
        _assetRefMeta,
        assetRef.isAcceptableOrUnknown(data['asset_ref']!, _assetRefMeta),
      );
    } else if (isInserting) {
      context.missing(_assetRefMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Assinatura map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Assinatura(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ratId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rat_id'],
      )!,
      storageMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_mode'],
      )!,
      assetRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_ref'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $AssinaturasTable createAlias(String alias) {
    return $AssinaturasTable(attachedDatabase, alias);
  }
}

class Assinatura extends DataClass implements Insertable<Assinatura> {
  final String id;
  final String ratId;
  final String storageMode;
  final String assetRef;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Assinatura({
    required this.id,
    required this.ratId,
    required this.storageMode,
    required this.assetRef,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rat_id'] = Variable<String>(ratId);
    map['storage_mode'] = Variable<String>(storageMode);
    map['asset_ref'] = Variable<String>(assetRef);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  AssinaturasCompanion toCompanion(bool nullToAbsent) {
    return AssinaturasCompanion(
      id: Value(id),
      ratId: Value(ratId),
      storageMode: Value(storageMode),
      assetRef: Value(assetRef),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Assinatura.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Assinatura(
      id: serializer.fromJson<String>(json['id']),
      ratId: serializer.fromJson<String>(json['ratId']),
      storageMode: serializer.fromJson<String>(json['storageMode']),
      assetRef: serializer.fromJson<String>(json['assetRef']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ratId': serializer.toJson<String>(ratId),
      'storageMode': serializer.toJson<String>(storageMode),
      'assetRef': serializer.toJson<String>(assetRef),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Assinatura copyWith({
    String? id,
    String? ratId,
    String? storageMode,
    String? assetRef,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Assinatura(
    id: id ?? this.id,
    ratId: ratId ?? this.ratId,
    storageMode: storageMode ?? this.storageMode,
    assetRef: assetRef ?? this.assetRef,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Assinatura copyWithCompanion(AssinaturasCompanion data) {
    return Assinatura(
      id: data.id.present ? data.id.value : this.id,
      ratId: data.ratId.present ? data.ratId.value : this.ratId,
      storageMode: data.storageMode.present
          ? data.storageMode.value
          : this.storageMode,
      assetRef: data.assetRef.present ? data.assetRef.value : this.assetRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Assinatura(')
          ..write('id: $id, ')
          ..write('ratId: $ratId, ')
          ..write('storageMode: $storageMode, ')
          ..write('assetRef: $assetRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ratId,
    storageMode,
    assetRef,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Assinatura &&
          other.id == this.id &&
          other.ratId == this.ratId &&
          other.storageMode == this.storageMode &&
          other.assetRef == this.assetRef &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class AssinaturasCompanion extends UpdateCompanion<Assinatura> {
  final Value<String> id;
  final Value<String> ratId;
  final Value<String> storageMode;
  final Value<String> assetRef;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const AssinaturasCompanion({
    this.id = const Value.absent(),
    this.ratId = const Value.absent(),
    this.storageMode = const Value.absent(),
    this.assetRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssinaturasCompanion.insert({
    required String id,
    required String ratId,
    required String storageMode,
    required String assetRef,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ratId = Value(ratId),
       storageMode = Value(storageMode),
       assetRef = Value(assetRef),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Assinatura> custom({
    Expression<String>? id,
    Expression<String>? ratId,
    Expression<String>? storageMode,
    Expression<String>? assetRef,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ratId != null) 'rat_id': ratId,
      if (storageMode != null) 'storage_mode': storageMode,
      if (assetRef != null) 'asset_ref': assetRef,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssinaturasCompanion copyWith({
    Value<String>? id,
    Value<String>? ratId,
    Value<String>? storageMode,
    Value<String>? assetRef,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return AssinaturasCompanion(
      id: id ?? this.id,
      ratId: ratId ?? this.ratId,
      storageMode: storageMode ?? this.storageMode,
      assetRef: assetRef ?? this.assetRef,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ratId.present) {
      map['rat_id'] = Variable<String>(ratId.value);
    }
    if (storageMode.present) {
      map['storage_mode'] = Variable<String>(storageMode.value);
    }
    if (assetRef.present) {
      map['asset_ref'] = Variable<String>(assetRef.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssinaturasCompanion(')
          ..write('id: $id, ')
          ..write('ratId: $ratId, ')
          ..write('storageMode: $storageMode, ')
          ..write('assetRef: $assetRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TechReportLocalDatabase extends GeneratedDatabase {
  _$TechReportLocalDatabase(QueryExecutor e) : super(e);
  $TechReportLocalDatabaseManager get managers =>
      $TechReportLocalDatabaseManager(this);
  late final $TecnicoLocalsTable tecnicoLocals = $TecnicoLocalsTable(this);
  late final $SessaoLocalsTable sessaoLocals = $SessaoLocalsTable(this);
  late final $RatsTable rats = $RatsTable(this);
  late final $AssinaturasTable assinaturas = $AssinaturasTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tecnicoLocals,
    sessaoLocals,
    rats,
    assinaturas,
  ];
}

typedef $$TecnicoLocalsTableCreateCompanionBuilder =
    TecnicoLocalsCompanion Function({
      required String id,
      required String nome,
      required String email,
      Value<String?> telefone,
      Value<String?> empresaNome,
      Value<String?> assinaturaPadraoRef,
      required bool pinConfigured,
      required bool biometriaHabilitada,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TecnicoLocalsTableUpdateCompanionBuilder =
    TecnicoLocalsCompanion Function({
      Value<String> id,
      Value<String> nome,
      Value<String> email,
      Value<String?> telefone,
      Value<String?> empresaNome,
      Value<String?> assinaturaPadraoRef,
      Value<bool> pinConfigured,
      Value<bool> biometriaHabilitada,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TecnicoLocalsTableFilterComposer
    extends Composer<_$TechReportLocalDatabase, $TecnicoLocalsTable> {
  $$TecnicoLocalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get empresaNome => $composableBuilder(
    column: $table.empresaNome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assinaturaPadraoRef => $composableBuilder(
    column: $table.assinaturaPadraoRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinConfigured => $composableBuilder(
    column: $table.pinConfigured,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get biometriaHabilitada => $composableBuilder(
    column: $table.biometriaHabilitada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TecnicoLocalsTableOrderingComposer
    extends Composer<_$TechReportLocalDatabase, $TecnicoLocalsTable> {
  $$TecnicoLocalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get empresaNome => $composableBuilder(
    column: $table.empresaNome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assinaturaPadraoRef => $composableBuilder(
    column: $table.assinaturaPadraoRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinConfigured => $composableBuilder(
    column: $table.pinConfigured,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get biometriaHabilitada => $composableBuilder(
    column: $table.biometriaHabilitada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TecnicoLocalsTableAnnotationComposer
    extends Composer<_$TechReportLocalDatabase, $TecnicoLocalsTable> {
  $$TecnicoLocalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get telefone =>
      $composableBuilder(column: $table.telefone, builder: (column) => column);

  GeneratedColumn<String> get empresaNome => $composableBuilder(
    column: $table.empresaNome,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assinaturaPadraoRef => $composableBuilder(
    column: $table.assinaturaPadraoRef,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pinConfigured => $composableBuilder(
    column: $table.pinConfigured,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get biometriaHabilitada => $composableBuilder(
    column: $table.biometriaHabilitada,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TecnicoLocalsTableTableManager
    extends
        RootTableManager<
          _$TechReportLocalDatabase,
          $TecnicoLocalsTable,
          TecnicoLocal,
          $$TecnicoLocalsTableFilterComposer,
          $$TecnicoLocalsTableOrderingComposer,
          $$TecnicoLocalsTableAnnotationComposer,
          $$TecnicoLocalsTableCreateCompanionBuilder,
          $$TecnicoLocalsTableUpdateCompanionBuilder,
          (
            TecnicoLocal,
            BaseReferences<
              _$TechReportLocalDatabase,
              $TecnicoLocalsTable,
              TecnicoLocal
            >,
          ),
          TecnicoLocal,
          PrefetchHooks Function()
        > {
  $$TecnicoLocalsTableTableManager(
    _$TechReportLocalDatabase db,
    $TecnicoLocalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TecnicoLocalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TecnicoLocalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TecnicoLocalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> telefone = const Value.absent(),
                Value<String?> empresaNome = const Value.absent(),
                Value<String?> assinaturaPadraoRef = const Value.absent(),
                Value<bool> pinConfigured = const Value.absent(),
                Value<bool> biometriaHabilitada = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TecnicoLocalsCompanion(
                id: id,
                nome: nome,
                email: email,
                telefone: telefone,
                empresaNome: empresaNome,
                assinaturaPadraoRef: assinaturaPadraoRef,
                pinConfigured: pinConfigured,
                biometriaHabilitada: biometriaHabilitada,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                required String email,
                Value<String?> telefone = const Value.absent(),
                Value<String?> empresaNome = const Value.absent(),
                Value<String?> assinaturaPadraoRef = const Value.absent(),
                required bool pinConfigured,
                required bool biometriaHabilitada,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TecnicoLocalsCompanion.insert(
                id: id,
                nome: nome,
                email: email,
                telefone: telefone,
                empresaNome: empresaNome,
                assinaturaPadraoRef: assinaturaPadraoRef,
                pinConfigured: pinConfigured,
                biometriaHabilitada: biometriaHabilitada,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TecnicoLocalsTableProcessedTableManager =
    ProcessedTableManager<
      _$TechReportLocalDatabase,
      $TecnicoLocalsTable,
      TecnicoLocal,
      $$TecnicoLocalsTableFilterComposer,
      $$TecnicoLocalsTableOrderingComposer,
      $$TecnicoLocalsTableAnnotationComposer,
      $$TecnicoLocalsTableCreateCompanionBuilder,
      $$TecnicoLocalsTableUpdateCompanionBuilder,
      (
        TecnicoLocal,
        BaseReferences<
          _$TechReportLocalDatabase,
          $TecnicoLocalsTable,
          TecnicoLocal
        >,
      ),
      TecnicoLocal,
      PrefetchHooks Function()
    >;
typedef $$SessaoLocalsTableCreateCompanionBuilder =
    SessaoLocalsCompanion Function({
      required String id,
      required String mode,
      required String tecnicoLocalId,
      required String status,
      required bool pinConfigured,
      required bool biometriaDisponivel,
      required bool biometriaHabilitada,
      required bool onboardingConcluido,
      Value<DateTime?> lastUnlockedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SessaoLocalsTableUpdateCompanionBuilder =
    SessaoLocalsCompanion Function({
      Value<String> id,
      Value<String> mode,
      Value<String> tecnicoLocalId,
      Value<String> status,
      Value<bool> pinConfigured,
      Value<bool> biometriaDisponivel,
      Value<bool> biometriaHabilitada,
      Value<bool> onboardingConcluido,
      Value<DateTime?> lastUnlockedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SessaoLocalsTableFilterComposer
    extends Composer<_$TechReportLocalDatabase, $SessaoLocalsTable> {
  $$SessaoLocalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tecnicoLocalId => $composableBuilder(
    column: $table.tecnicoLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinConfigured => $composableBuilder(
    column: $table.pinConfigured,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get biometriaDisponivel => $composableBuilder(
    column: $table.biometriaDisponivel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get biometriaHabilitada => $composableBuilder(
    column: $table.biometriaHabilitada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingConcluido => $composableBuilder(
    column: $table.onboardingConcluido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUnlockedAt => $composableBuilder(
    column: $table.lastUnlockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessaoLocalsTableOrderingComposer
    extends Composer<_$TechReportLocalDatabase, $SessaoLocalsTable> {
  $$SessaoLocalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tecnicoLocalId => $composableBuilder(
    column: $table.tecnicoLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinConfigured => $composableBuilder(
    column: $table.pinConfigured,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get biometriaDisponivel => $composableBuilder(
    column: $table.biometriaDisponivel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get biometriaHabilitada => $composableBuilder(
    column: $table.biometriaHabilitada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingConcluido => $composableBuilder(
    column: $table.onboardingConcluido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUnlockedAt => $composableBuilder(
    column: $table.lastUnlockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessaoLocalsTableAnnotationComposer
    extends Composer<_$TechReportLocalDatabase, $SessaoLocalsTable> {
  $$SessaoLocalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get tecnicoLocalId => $composableBuilder(
    column: $table.tecnicoLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get pinConfigured => $composableBuilder(
    column: $table.pinConfigured,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get biometriaDisponivel => $composableBuilder(
    column: $table.biometriaDisponivel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get biometriaHabilitada => $composableBuilder(
    column: $table.biometriaHabilitada,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingConcluido => $composableBuilder(
    column: $table.onboardingConcluido,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUnlockedAt => $composableBuilder(
    column: $table.lastUnlockedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SessaoLocalsTableTableManager
    extends
        RootTableManager<
          _$TechReportLocalDatabase,
          $SessaoLocalsTable,
          SessaoLocal,
          $$SessaoLocalsTableFilterComposer,
          $$SessaoLocalsTableOrderingComposer,
          $$SessaoLocalsTableAnnotationComposer,
          $$SessaoLocalsTableCreateCompanionBuilder,
          $$SessaoLocalsTableUpdateCompanionBuilder,
          (
            SessaoLocal,
            BaseReferences<
              _$TechReportLocalDatabase,
              $SessaoLocalsTable,
              SessaoLocal
            >,
          ),
          SessaoLocal,
          PrefetchHooks Function()
        > {
  $$SessaoLocalsTableTableManager(
    _$TechReportLocalDatabase db,
    $SessaoLocalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessaoLocalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessaoLocalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessaoLocalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> tecnicoLocalId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> pinConfigured = const Value.absent(),
                Value<bool> biometriaDisponivel = const Value.absent(),
                Value<bool> biometriaHabilitada = const Value.absent(),
                Value<bool> onboardingConcluido = const Value.absent(),
                Value<DateTime?> lastUnlockedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessaoLocalsCompanion(
                id: id,
                mode: mode,
                tecnicoLocalId: tecnicoLocalId,
                status: status,
                pinConfigured: pinConfigured,
                biometriaDisponivel: biometriaDisponivel,
                biometriaHabilitada: biometriaHabilitada,
                onboardingConcluido: onboardingConcluido,
                lastUnlockedAt: lastUnlockedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mode,
                required String tecnicoLocalId,
                required String status,
                required bool pinConfigured,
                required bool biometriaDisponivel,
                required bool biometriaHabilitada,
                required bool onboardingConcluido,
                Value<DateTime?> lastUnlockedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SessaoLocalsCompanion.insert(
                id: id,
                mode: mode,
                tecnicoLocalId: tecnicoLocalId,
                status: status,
                pinConfigured: pinConfigured,
                biometriaDisponivel: biometriaDisponivel,
                biometriaHabilitada: biometriaHabilitada,
                onboardingConcluido: onboardingConcluido,
                lastUnlockedAt: lastUnlockedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessaoLocalsTableProcessedTableManager =
    ProcessedTableManager<
      _$TechReportLocalDatabase,
      $SessaoLocalsTable,
      SessaoLocal,
      $$SessaoLocalsTableFilterComposer,
      $$SessaoLocalsTableOrderingComposer,
      $$SessaoLocalsTableAnnotationComposer,
      $$SessaoLocalsTableCreateCompanionBuilder,
      $$SessaoLocalsTableUpdateCompanionBuilder,
      (
        SessaoLocal,
        BaseReferences<
          _$TechReportLocalDatabase,
          $SessaoLocalsTable,
          SessaoLocal
        >,
      ),
      SessaoLocal,
      PrefetchHooks Function()
    >;
typedef $$RatsTableCreateCompanionBuilder =
    RatsCompanion Function({
      required String id,
      required String authorId,
      required String ownerType,
      required String numero,
      required String clienteNome,
      required String descricao,
      required String status,
      required String syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$RatsTableUpdateCompanionBuilder =
    RatsCompanion Function({
      Value<String> id,
      Value<String> authorId,
      Value<String> ownerType,
      Value<String> numero,
      Value<String> clienteNome,
      Value<String> descricao,
      Value<String> status,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$RatsTableFilterComposer
    extends Composer<_$TechReportLocalDatabase, $RatsTable> {
  $$RatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clienteNome => $composableBuilder(
    column: $table.clienteNome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RatsTableOrderingComposer
    extends Composer<_$TechReportLocalDatabase, $RatsTable> {
  $$RatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clienteNome => $composableBuilder(
    column: $table.clienteNome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RatsTableAnnotationComposer
    extends Composer<_$TechReportLocalDatabase, $RatsTable> {
  $$RatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get ownerType =>
      $composableBuilder(column: $table.ownerType, builder: (column) => column);

  GeneratedColumn<String> get numero =>
      $composableBuilder(column: $table.numero, builder: (column) => column);

  GeneratedColumn<String> get clienteNome => $composableBuilder(
    column: $table.clienteNome,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$RatsTableTableManager
    extends
        RootTableManager<
          _$TechReportLocalDatabase,
          $RatsTable,
          Rat,
          $$RatsTableFilterComposer,
          $$RatsTableOrderingComposer,
          $$RatsTableAnnotationComposer,
          $$RatsTableCreateCompanionBuilder,
          $$RatsTableUpdateCompanionBuilder,
          (Rat, BaseReferences<_$TechReportLocalDatabase, $RatsTable, Rat>),
          Rat,
          PrefetchHooks Function()
        > {
  $$RatsTableTableManager(_$TechReportLocalDatabase db, $RatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<String> ownerType = const Value.absent(),
                Value<String> numero = const Value.absent(),
                Value<String> clienteNome = const Value.absent(),
                Value<String> descricao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatsCompanion(
                id: id,
                authorId: authorId,
                ownerType: ownerType,
                numero: numero,
                clienteNome: clienteNome,
                descricao: descricao,
                status: status,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String authorId,
                required String ownerType,
                required String numero,
                required String clienteNome,
                required String descricao,
                required String status,
                required String syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatsCompanion.insert(
                id: id,
                authorId: authorId,
                ownerType: ownerType,
                numero: numero,
                clienteNome: clienteNome,
                descricao: descricao,
                status: status,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RatsTableProcessedTableManager =
    ProcessedTableManager<
      _$TechReportLocalDatabase,
      $RatsTable,
      Rat,
      $$RatsTableFilterComposer,
      $$RatsTableOrderingComposer,
      $$RatsTableAnnotationComposer,
      $$RatsTableCreateCompanionBuilder,
      $$RatsTableUpdateCompanionBuilder,
      (Rat, BaseReferences<_$TechReportLocalDatabase, $RatsTable, Rat>),
      Rat,
      PrefetchHooks Function()
    >;
typedef $$AssinaturasTableCreateCompanionBuilder =
    AssinaturasCompanion Function({
      required String id,
      required String ratId,
      required String storageMode,
      required String assetRef,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$AssinaturasTableUpdateCompanionBuilder =
    AssinaturasCompanion Function({
      Value<String> id,
      Value<String> ratId,
      Value<String> storageMode,
      Value<String> assetRef,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$AssinaturasTableFilterComposer
    extends Composer<_$TechReportLocalDatabase, $AssinaturasTable> {
  $$AssinaturasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratId => $composableBuilder(
    column: $table.ratId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageMode => $composableBuilder(
    column: $table.storageMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetRef => $composableBuilder(
    column: $table.assetRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssinaturasTableOrderingComposer
    extends Composer<_$TechReportLocalDatabase, $AssinaturasTable> {
  $$AssinaturasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratId => $composableBuilder(
    column: $table.ratId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageMode => $composableBuilder(
    column: $table.storageMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetRef => $composableBuilder(
    column: $table.assetRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssinaturasTableAnnotationComposer
    extends Composer<_$TechReportLocalDatabase, $AssinaturasTable> {
  $$AssinaturasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ratId =>
      $composableBuilder(column: $table.ratId, builder: (column) => column);

  GeneratedColumn<String> get storageMode => $composableBuilder(
    column: $table.storageMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetRef =>
      $composableBuilder(column: $table.assetRef, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$AssinaturasTableTableManager
    extends
        RootTableManager<
          _$TechReportLocalDatabase,
          $AssinaturasTable,
          Assinatura,
          $$AssinaturasTableFilterComposer,
          $$AssinaturasTableOrderingComposer,
          $$AssinaturasTableAnnotationComposer,
          $$AssinaturasTableCreateCompanionBuilder,
          $$AssinaturasTableUpdateCompanionBuilder,
          (
            Assinatura,
            BaseReferences<
              _$TechReportLocalDatabase,
              $AssinaturasTable,
              Assinatura
            >,
          ),
          Assinatura,
          PrefetchHooks Function()
        > {
  $$AssinaturasTableTableManager(
    _$TechReportLocalDatabase db,
    $AssinaturasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssinaturasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssinaturasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssinaturasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ratId = const Value.absent(),
                Value<String> storageMode = const Value.absent(),
                Value<String> assetRef = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssinaturasCompanion(
                id: id,
                ratId: ratId,
                storageMode: storageMode,
                assetRef: assetRef,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ratId,
                required String storageMode,
                required String assetRef,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssinaturasCompanion.insert(
                id: id,
                ratId: ratId,
                storageMode: storageMode,
                assetRef: assetRef,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssinaturasTableProcessedTableManager =
    ProcessedTableManager<
      _$TechReportLocalDatabase,
      $AssinaturasTable,
      Assinatura,
      $$AssinaturasTableFilterComposer,
      $$AssinaturasTableOrderingComposer,
      $$AssinaturasTableAnnotationComposer,
      $$AssinaturasTableCreateCompanionBuilder,
      $$AssinaturasTableUpdateCompanionBuilder,
      (
        Assinatura,
        BaseReferences<
          _$TechReportLocalDatabase,
          $AssinaturasTable,
          Assinatura
        >,
      ),
      Assinatura,
      PrefetchHooks Function()
    >;

class $TechReportLocalDatabaseManager {
  final _$TechReportLocalDatabase _db;
  $TechReportLocalDatabaseManager(this._db);
  $$TecnicoLocalsTableTableManager get tecnicoLocals =>
      $$TecnicoLocalsTableTableManager(_db, _db.tecnicoLocals);
  $$SessaoLocalsTableTableManager get sessaoLocals =>
      $$SessaoLocalsTableTableManager(_db, _db.sessaoLocals);
  $$RatsTableTableManager get rats => $$RatsTableTableManager(_db, _db.rats);
  $$AssinaturasTableTableManager get assinaturas =>
      $$AssinaturasTableTableManager(_db, _db.assinaturas);
}
