# perl_RSS
Analyse automatisée des flux RSS en Perl

# 1. Objectif du programme

Le programme avait initialement pour but d’analyser les tendances des articles de blogs via des flux RSS, en Perl. Il prenait en entrée une URL ou un fichier texte contenant un flux RSS, avec des options en ligne de commande (telles que le nombre d’articles à analyser, par défaut 20). À l’aide des modules Perl `LWP::Simple` et `XML::RSS`, il extrayait des données issues de blogs ou sites d’actualités, pour produire un fichier structuré (CSV ou JSON) contenant, pour chaque article : **titre, date, auteur, catégorie, nombre de mots, et mots-clés fréquents** après nettoyage. 

Cette version permettait des analyses statistiques telles que la fréquence de publication ou la longueur moyenne des articles. Cependant, après échange avec l’assistant **M. Escouflaire Louis**, il a été constaté que ce fonctionnement pouvait échouer selon les URLs fournies (incompatibilités ou limitations de certains flux). 

Le projet a donc été redéfini : il vise désormais à analyser automatiquement des **flux RSS issus de trois sites d’actualité français représentant des orientations politiques différentes (Gauche, Droite, Extrême Droite)**: \

- **L'Humanite comme** [https://www.humanite.fr/](https://www.humanite.fr/) site de gauche. 

- **Le Figaro** [https://www.lefigaro.fr/](https://www.lefigaro.fr/) site de droite. 

- **Present** [https://www.present.fr/](https://www.present.fr/) site d'Extreme droite.

afin de **détecter et comparer les tendances éditoriales autour d’un mot-clé donné** (thème de recherche). Cette nouvelle approche permet une analyse comparative ciblée et plus robuste du traitement médiatique selon les sensibilités politiques.

# 2. Entrées et paramètres

- **Entrée principale** : aucun fichier requis. Le programme télécharge directement les flux RSS en ligne.

- **Arguments en ligne de commande** :

  - `--motcle` (**optionnel**) : mot ou expression clé à rechercher dans le contenu ou la  descriptions des articles **(par défaut c'est 'économie')**.
  
Le mot ou expression à rechercher est  fouilleé dans le contenue ou la description de l'article. 

  - `--max` (**optionnel**) : nombre maximal d’articles à analyser par site **(défaut : 10)**.
  - `--keywords` (**optionnel**) : nombre maximal de mots-clés fréquents à afficher par article **(défaut : 5)**.
  - `--stopwords` (**optionnel**) : permet à l'utilisateur d'exclure un mot ou une liste de mots qu'il ne souhaite pas voir apparaître dans les statistiques ou dans les fichiers CSV. Ceci vaut **('')** par défaut.
 
# 3. Sorties

- Un fichier **CSV** nommé `articles_analyse.csv` listant les articles filtrés par mot-clé, avec :
  - Titre, lien, date, auteur, catégorie
  - Nombre total de mots dans l’article
  - Liste des mots-clés fréquents extraits du texte avec le nombre d'occurance 

- Un fichier **CSV** nommé `keywords_stats.csv` listant les mots-clés, avec :
  - les mots-clés stockés 
  -  le nombre d'occurences par mots 
  - le site où le mot-clé est utilisé 
  
- Un fichier **PNG** (graphique) :
  - Visualisation du **volume d’articles par site politique** pour la thématique.
  
- Une **sortie console** avec un résumé :
  - Nombre d’articles disponibles et traités par site
  - Titres des articles contenant le mot-clé
  - Des messages confirmant écriture dans le fichier csv et le traçage du graphique
  - Des statistiques globales et puis par orientation politique par occurences de mots
  
# 4. Fonctionnement interne et choix techniques

## Récupération des données
dans ce travail , nous avons fait le choix d'utiliser une boucle pour télécharger  le flux  de donner 

- Modules Perl : `LWP::Simple`(pour la méthode simple), `LWP::UserAgent`( pour la seconde méthode , en se passant pour `Mozilla/5.0`).
- `XML::RSS` pour le parsing des flux RSS

## Filtrage par mot-clé
- Recherche insensible à la casse sur les titres et descriptions
Nous avons rajouté dans la liste de mots-clés, les mots comme: figaro , humanité  cela pour rendre le tri plus facile. 

## Extraction du contenu complet
- Récupération HTML complète des articles
- Parsing via `HTML::TreeBuilder::XPath` pour cibler les paragraphes spécifiques

## Nettoyage et analyse textuelle
- Suppression des caractères spéciaux : `Text::Unidecode`
- Suppression des mots vides en français : `Lingua::StopWords`
- Comptage des mots fréquents pour extraire les mots-clés dominants

## Visualisation
- Graphique en barres avec le module `Imager`
- Couleurs différenciées selon l’orientation politique des sources

# 5. Points originaux et difficultés rencontrées

## Originalité
- Intégration de plusieurs flux RSS politiquement variés pour analyse comparative
- Extraction ciblée du contenu HTML avec XPath selon chaque site
- Génération dynamique d’un graphique coloré pour illustrer les tendances quantitatives en volume d'articles. 
_ Géneration de statistiques de bases  

## Difficultés rencontrées
- Variabilité des structures HTML selon les sites (nécessitant XPath sur mesure)
- Fiabilité des flux RSS (certains indisponibles ou mal formés)
- Nettoyage textuel complexe pour garantir la qualité des mots-clés extraits
- Nécessité de changer manuellement  la police de caractère  pour affichage  du graphique ,
  si il n'est pas exécuté  sur  MacOs.
  
# 6. Améliorations possibles

- **Robustesse** :
  - Meilleure gestion des erreurs (flux manquants, structures HTML évolutives)
  _ possibilité  de suppression  du nombre de boucles , ce qui ferais  le programme s’exécuter plus rapidement
  
- **Analyse approfondie** :
  - Ajout de corrélations (ex. : longueur des articles vs fréquence des mots-clés)
  - possibilité  de visualisation  ( ex tracer un nuage de mots en fonction de l'orientation politique, problème  absence de module perl. )
- **Performance** :
  - Parallélisation du téléchargement et du traitement des données 
  
- **Multi-langues** :
  - Ajout de la détection automatique de langue et des stopwords correspondants

---

# 7 Annexes (Exemple d’exécution) 

nous noterons ici que les sorties  du code dépendent  du jour  ou de la période   à la quelle est exécutée  le code. 
programme exécuté le 23/05/2025 à 15h56

*` perl projet_de_fin_annee.pl --motcle 'loi' --max 30 --keywords 7`*

## sortie console : 
==================================================\
🔍 Analyse du site : Droite\
==================================================\
📄 Nombre total d'articles disponibles : 20\
✅ Nombre d'articles traités : 20

📰 Articles contenant le mot-clé "loi" :20
  • Article 1 : Guerre commerciale : pourquoi l’Union européenne a beaucoup à perdre dans le conflit avec Donald Trump\
  • Article 2 : Donald Trump menace l’Union européenne de 50% de droits de douane à partir du 1er juin\
  • Article 3 : Menaces douanières de Trump : les Bourses européennes dévissent, le CAC 40 s’enfonce de près de 3%\
  • Article 4 : Droits de douane : Donald Trump veut appliquer une hausse de 25% à Apple si les iPhone ne sont pas fabriqués aux États-Unis\
  • Article 5 : iPhone, PC, puces IA… Le mirage trumpien d’une industrie de la tech relocalisée aux États-Unis\
  • Article 6 : Opération «Mario» : un évêque gallican interpellé dans le cadre du réseau pédocriminel s'est défenestré\
  • Article 7 : Un ambulancier, un professeur, un internaute de Coco... Derrière l’opération «Mario», l’ombre d’un réseau pédocriminel de «bons pères de famille»\
  • Article 8 : «Je présente mes excuses à Léna Situations» : une macroniste suscite un tollé en associant une tenue de l’influenceuse à l’entrisme des Frères musulmans\
  • Article 9 : Laurence de Charette : « Pourquoi les notes à l’école ne servent plus à rien »\
  • Article 10 : Pollution plastique, pêche illégale... François Bayrou présidera lundi un comité interministériel de la mer à Saint-Nazaire\
  • Article 11 : «La confiance est rompue» : ras-le-bol dans la Vésubie après un nouveau report des travaux post-tempête Alex\
  • Article 12 : États-Unis : Harvard attaque en justice l'administration Trump sur l'interdiction d'accueillir des étudiants étrangers\
  • Article 13 : Guerre en Ukraine : la grande désillusion des Européens leurrés par Donald Trump\
  • Article 14 : Guerre en Ukraine : Trump annonce un «gros échange de prisonniers» entre Moscou et Kiev\
  • Article 15 : Guerre Russie-Ukraine : quel rôle pourrait jouer le Vatican dans des négociations de paix ?\
  • Article 16 : Guerre en Ukraine : Sergueï Lavrov émet des doutes quant au choix du Vatican comme lieu de pourparlers\
  • Article 17 : Tribune contre le « génocide à Gaza » : Catherine Deneuve rejoint Juliette Binoche, Ralph Fiennes, Richard Gere, Javier Bardem, Pedro Almodovar...\
  • Article 18 : «On m’a pris pour un pigeon», Stéphane verbalisé par un agent SNCF pour avoir jeté une cigarette éteinte dans une poubelle de gare\
  • Article 19 : À l’Ascension, ou début juin : faut-il s’attendre à de nouvelles grèves à la SNCF dans les prochaines semaines ?\
  • Article 20 : «Plus c’est jeune, plus c’est cher» : hôtels miteux, proxénètes de 14 ans, recrutement en ligne… Dans l’enfer du trafic de prostitution des mineurs\
--------------------------------------------------\
==================================================\
🔍 Analyse du site : ExtremeDroite\
==================================================\
📄 Nombre total d'articles disponibles : 10\
✅ Nombre d'articles traités : 10

📰 Articles contenant le mot-clé "loi" :7
  • Article 1 : Vivre à Bali : guide complet pour s’expatrier en France et conseils pratiques avant de partir
  • Article 2 : Vivre à Bordeaux : les avantages et réalités de la vie dans la ville bordelaise
  • Article 3 : Vivre à Montpellier : est-ce vraiment la ville idéale ?
  • Article 4 : Vivre à l’île Maurice : guide complet pour une expatriation réussie
  • Article 7 : Les quartiers à éviter à Montpellier : guide complet des zones à connaître avant de s’installer
  • Article 8 : Quartiers à éviter aux Ulis : guide complet pour vivre en sécurité dans cette ville
  • Article 10 : Quartiers à éviter à Noisy-le-Grand : Pavé Neuf, La Varenne et zones dangereuses à connaître
--------------------------------------------------\
==================================================\
🔍 Analyse du site : Gauche\
==================================================\
📄 Nombre total d'articles disponibles : 20\
✅ Nombre d'articles traités : 20

📰 Articles contenant le mot-clé "loi" :20
  • Article 1 : Procès Le Scouarnec : l’heure du réquisitoire dans une affaire d’une ampleur inédite\
  • Article 2 : Vivre dans l’angoisse en travaillant pour nourrir ses concitoyens\
  • Article 3 : Printemps 1945 : après des décennies de luttes, les Françaises remportent la bataille des urnes\
  • Article 4 : Guillaume Roubaud-Quashie et Côme Simien, historiens : « Le jacobinisme tient une place très forte dans la vie politique française »\
  • Article 5 : Les collaborateurs gazaouis des médias français sont en danger de mort, il faut les évacuer\
  • Article 6 : Donald Trump interdit à Harvard de recruter des étudiants étrangers\
  • Article 7 : Marie-Claude Vaillant-Couturier, à la vie, à la mort, à l’amour : un documentaire à découvrir sur France 5\
  • Article 8 : Chasse au trésor au Puy du Fou : à la recherche de toujours plus de propagande réactionnaire\
  • Article 9 : « J’ai découvert par accident que j’étais capable d’inventer des mélodies » : Julien Clerc nous raconte « Une vie »\
  • Article 10 : Plus 10 % de revenus pour les riches, moins 10 % pour les pauvres… Le populiste Donald Trump fait adopter son budget ultralibéral\
  • Article 11 : Améliorer la prise en charge psychiatrique : des solutions existent !
  • Article 12 : À Cannes, l’influenceuse Lena Situations obligée de réagir au cyberharcèlement islamophobe suite à un message d’une cadre macroniste\
  • Article 13 : Santé mentale : grande cause nationale, et l’urgence au travail ?\
  • Article 14 : Annecy, un bol d’air et d’eau pure\
  • Article 15 : Aux côtés de Marie Lys, enceinte et menacée d’expulsion : on a suivi la mobilisation de Droit au Logement\
  • Article 16 : Le cannelé, le luxe de la simplicité\
  • Article 17 : Rugby : les joueuses du Stade français demandent la démission d’un dirigeant après des propos sexistes et lesbophobes\
  • Article 18 : « Scarlett O’Hara » : Caroline Silhol incarne une passionnante Vivien Leigh\
  • Article 19 : Serge Rezvani : « Les gens riches sont insupportablement cons ! »\
  • Article 20 : Fleury-Mérogis, comment la ville a appris à cohabiter avec la plus grande prison d’Europe\
--------------------------------------------------\
Analyse terminée. Résultats sauvegardés dans 'articles_analyse.csv'.\

📊 Statistiques des mots-clés :\

🔠 Top 7 mots-clés globaux :\
  • législatives (14603 occurrences)\
  • plus (1643 occurrences)\
  • mai (1522 occurrences)\
  • publicité (1450 occurrences)\
  • trump (1337 occurrences)\
  • voyage (1285 occurrences)\
  • publié (1187 occurrences)\

🏛️ Top 7 mots-clés pour Droite :\
  • législatives (14602 occurrences)\
  • publicité (1450 occurrences)\
  • voyage (1284 occurrences)\
  • passer (1123 occurrences)\
  • résultats (1113 occurrences)\
  • trump (1075 occurrences)\
  • plus (712 occurrences)\

🏛️ Top 7 mots-clés pour ExtremeDroite :\
  • ville (295 occurrences)\
  • vie (267 occurrences)\
  • île (179 occurrences)\
  • entre (174 occurrences)\
  • montpellier (171 occurrences)\
  • plus (171 occurrences)\
  • quartiers (162 occurrences)\

🏛️ Top 7 mots-clés pour Gauche :\
  • mai (1389 occurrences)\
  • publié (1183 occurrences)\
  • plus (760 occurrences)\
  • nécessaire (651 occurrences)
  • vie (555 occurrences)\
  • vidéos (434 occurrences)\
  • politique (391 occurrences)\
Graphique politique généré : articles_par_site.png


## seconde exécution avec l'option stopwords  
Nous allons assayer de retirer le mot plus de nos statistiques 

programme exécuté le 26/05/2025 à 12h20   

*` perl projet_de_fin_annee.pl --motcle 'loi' --max 30 --keywords 7 --stopwords 'plus'`* 

## sortie console 2
==================================================\
🔍 Analyse du site : Droite\
==================================================\
📄 Nombre total d'articles disponibles : 20\
✅ Nombre d'articles traités : 20

📰 Articles contenant le mot-clé "loi" :20\
  • Article 1 : Rachida Dati s’oppose aux Républicains en affirmant que «le macronisme existe»\
  • Article 2 : L’éditorial d’Yves Thréard : «Ainsi va la “fin du macronisme”»\
  • Article 3 : La droite mise sur l’obsolescence programmée du macronisme\
  • Article 4 : La Cour des comptes tire la sonnette d’alarme sur la trajectoire «hors de contrôle» du «trou de la Sécu»\
  • Article 5 : Colère des agriculteurs : le président des Jeunes agriculteurs veut «retrouver le même niveau de compétitivité que nos voisins européens»\
  • Article 6 : «On essaye de garder la tête hors de l’eau»: pourquoi les agriculteurs gagnent Paris pour mettre la pression sur les députés\
  • Article 7 : «C’est la foire aux idées»: la petite musique des hausses d’impôts irrite jusque dans le camp macroniste\
  • Article 8 : Manifestation des agriculteurs, bombardement d’une école à Gaza, record de drones russes... Les 3 infos à retenir à la mi-journée\
  • Article 9 : Lors des célébrations du titre, un joueur de l’UBB annonce sa candidature à la mairie de Bordeaux (vidéo)\
  • Article 10 : Justin Bieber fait un retour inattendu sur scène après ses récentes déclarations sur sa santé mentale\
  • Article 11 : Gaza : plus de 30 morts dans le bombardement d'une école par Israël, Tsahal évoque la présence de «terroristes»\
  • Article 12 : Gaza: le chef de la nouvelle fondation humanitaire soutenue par Washington démissionne\
  • Article 13 : EN DIRECT - Roland Garros : Hugo Gaston lance la grande journée des Français avec Gasquet, Fils et Garcia\
  • Article 14 : Roland-Garros : jusqu’à 500 euros, les t-shirts distribués en hommage à Nadal vendus sur Vinted\
  • Article 15 : « Merci la France, merci Paris ! » : Roland-Garros a dit adieu à son roi Rafael Nadal\
  • Article 16 : Roland-Garros : «Le jour où j’arrêterai, je sais que ce sera dur» confie Stanislas Wawrinka\
  • Article 17 : La maladie d’Alzheimer peut désormais être diagnostiquée avec une simple prise de sang\
  • Article 18 : Guerre en Ukraine : Trump affirme que Poutine «est devenu complètement fou»\
  • Article 19 : Guerre en Ukraine : record de drones lancés par la Russie depuis le début de son invasion en 2022\
  • Article 20 : «Papa rentre à la maison»: quand des anciens soldats ukrainiens profitent d’un échange de prisonniers avec la Russie\
--------------------------------------------------\
==================================================\
🔍 Analyse du site : ExtremeDroite\
==================================================\
📄 Nombre total d'articles disponibles : 10\
✅ Nombre d'articles traités : 10

📰 Articles contenant le mot-clé "loi" :9
  • Article 1 : Vivre à La Rochelle : avis, informations et raisons de s’installer dans cette ville idéale\
  • Article 2 : Vivre à Aix-en-Provence : la ville idéale ? Découvrez nos avis et bonnes raisons de s’y installer\
  • Article 3 : Vivre à Nîmes : avis, raisons et guide pour s’installer dans la ville idéale\
  • Article 4 : Vivre à Erdeven : informations pratiques pour bien s’installer dans cette ville du Morbihan\
  • Article 5 : Vivre à Marseille : guide complet des quartiers, avantages et inconvénients pour s’installer\
  • Article 7 : Vivre à Bali : guide complet pour s’expatrier en France et conseils pratiques avant de partir\
  • Article 8 : Vivre à Bordeaux : les avantages et réalités de la vie dans la ville bordelaise\
  • Article 9 : Vivre à Montpellier : est-ce vraiment la ville idéale ?\
  • Article 10 : Vivre à l’île Maurice : guide complet pour une expatriation réussie\
--------------------------------------------------\
==================================================\
🔍 Analyse du site : Gauche\
==================================================\
📄 Nombre total d'articles disponibles : 20\
✅ Nombre d'articles traités : 20

📰 Articles contenant le mot-clé "loi" :20
  • Article 1 : « Cette découverte est majeure puisqu’il s’agit des plus grosses molécules détectées sur Mars », explique Caroline Freissinet, astrochimiste au CNRS\
  • Article 2 : Luttes paysannes et notes ubuesques rédigées à Bruxelles\
  • Article 3 : Loi Omnibus : une enquête ouverte contre la Commission européenne sur le projet qui détricote le Green Deal\
  • Article 4 : Sabotage d’installations électriques à Cannes et Nice : des revendications anarchistes en cours d’authentification\
  • Article 5 : « Poutine est devenu complètement fou » : derrière les déclarations de Trump, un cessez-le-feu en Ukraine toujours plus improbable\
  • Article 6 : Mort de Marcel Ophüls : Comment « le Chagrin et la Pitié » a changé à jamais la vision de la France sous l’Occupation
  • Article 7 : « Ma façon de militer, c’est de faire rire ceux qui luttent » : Waly Dia sur scène pour l’édition 2025 de la Fête de l’Humanité\
  • Article 8 : Recours au référendum : à quoi joue Macron ? (2/2)\
  • Article 9 : Disparition de Sebastião Salgado, l’UBB champion d’Europe, Palme d’or pour l’Iranien Jafar Panahi, poursuite du Génocide à Gaza… ce qu’il ne fallait pas manquer ce week-end\
  • Article 10 : Théâtre : L’univers masculin n’est (heureusement) plus ce qu’il était\
  • Article 11 : Génocide, un mot tabou pour qualifier l’anéantissement de Gaza ?\
  • Article 12 : En Asie du Sud-Est Emmanuel Macron prône une « troisième voie » française\
  • Article 13 : À Gaza, un génocide qui ne dit pas son nom\
  • Article 14 : Francesca Albanese, rapporteure spéciale de l’ONU pour les territoires palestiniens occupés : « Les Palestiniens sont pris pour cible en\ tant que peuple »\
  • Article 15 : Immigration : le Conseil de l’Europe résiste aux pressions et refuse d’affaiblir la Convention des droits de l’Homme\
  • Article 16 : Congrès du PS : L’Humanité organise le débat entre Olivier Faure, Boris Vallaud et Nicolas Mayer-Rossignol\
  • Article 17 : Corruption : l’ancien ministre de la Sécurité publique du Mexique condamné à payer 2,4 milliards de dollars\
  • Article 18 : Tennis : Garcia-Gasquet, de la terre à la der des ders\
  • Article 19 : Noëlle Vincensini, figure corse de la Résistance, est décédée à l’âge de 98 ans\
  • Article 20 : Primaire à gauche : l’idée d’une candidature unique a du plomb dans l’aile\
--------------------------------------------------\
Analyse terminée. Résultats sauvegardés dans 'articles_analyse.csv'.\

📊 Statistiques des mots-clés :\

🔠 Top 7 mots-clés globaux :\
  • législatives (11244 occurrences)\
  • résultats (5176 occurrences)\
  • coupe (2914 occurrences)\
  • actu (2720 occurrences)\
  • classement (2685 occurrences)\
  • mai (2166 occurrences)\
  • lien (2156 occurrences)\

🏛️ Top 7 mots-clés pour Droite :\
  • législatives (11244 occurrences)\
  • résultats (5174 occurrences)\
  • coupe (2913 occurrences)\
  • classement (2685 occurrences)\
  • actu (2597 occurrences)\
  • lien (2086 occurrences)\
  • calendrier (1626 occurrences)\

🏛️ Top 7 mots-clés pour ExtremeDroite :\
  • ville (467 occurrences)\
  • vie (372 occurrences)\
  • entre (227 occurrences)\
  • cette (200 occurrences)\
  • aix (197 occurrences)\
  • île (178 occurrences)\
  • provence (156 occurrences)\

🏛️ Top 7 mots-clés pour Gauche :\
  • mai (2093 occurrences)\
  • génocide (1198 occurrences)\
  • publié (932 occurrences)\
  • gaza (689 occurrences)\
  • nécessaire (650 occurrences)\
  • vidéos (420 occurrences)\
  • politique (347 occurrences)\
Graphique politique généré : articles_par_site.png\


