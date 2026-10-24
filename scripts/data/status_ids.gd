class_name StatusIds

const WET = "wet"
const CHARGED = "charged"
const BURNING = "burning"
const ROOTED = "rooted"
const WINDMARK = "windmark"
const STUNNED = "stunned"
## Marque d'Ombre : l'ennemi encaisse plus de dégâts de TOUTES les sources.
const MARKED = "marked"
## Givre : ralentissement CUMULATIF et durable (voir EnemyBase.add_chill).
## Se distingue du ralentissement de l'Eau (bref, accessoire à la combo WET) et
## de celui de l'Air (très court, accessoire à la repoussée).
const CHILLED = "chilled"
## Poussière de roche : la Terre n'appliquait aucun statut, donc elle ne
## participait à aucune réaction. Ce statut est son entrée dans le système
## (voir la Tempête de Sable, Terre + Air).
const DUSTY = "dusty"
## Poison (Nature) : dégâts sur la durée en % des PV max — voir EnemyBase.
const POISONED = "poisoned"
