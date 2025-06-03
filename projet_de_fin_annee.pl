#===================================================================================================

# Script : projet_de_fin_annee.pl

# Auteur : Belanov Bogning <belanov.bogning@student.uclouvain.be>

# Date   : 13/05/2025

#====================================================================================================

# projet_de_fin_annee.pl  permets d'analyser des tendances
# d'articles de blocs Via RSS(Perl)
#
# il analyse 3 sites internets  en français prédéfinies  qui sont ici:
#
# Humanite  : url =  'https://www.humanite.fr/rss/actu.rss' # L'Humanité (gauche)
# Le Figaro : url =  'https://www.lefigaro.fr/rss/figaro_actualites.xml', # Le Figaro (droite)
# Present   : url =  'https://www.present.fr/rss'                   # Présent (extrême droite)
#
# ses trois cites sont stockes dans une table de hachage
# exemple de structure html d'un site en ligne:
#<item>
    #<title>Titre de l'article</title>
    #<link>https://example.com/article</link>
    #<description>Ceci est la description de l'article.</description>
    #<pubDate>Mon, 13 May 2025 10:00:00 GMT</pubDate>
    #<author>author@example.com</author>
    #<category>Actualités</category>
#</item> ;

# il prend 3 arguments en options en ligne de commande(Getopt::Long):
#
# max       : le nombre max d'articles à analyser est fixé à (20 par défaut).
# motcle    : un mot ou groupe de mots  comme thème de la recherche.
# keywords  : le nombres max de mots clé ou de groupes de mots à afficher
# stopwords : un mot ou groupe de mots que l'utilisateur ne veux pas voir pris en compte
# dans ses statistiques.
#
#sorties   du programme:
# print dans la sortie standard le nombre d'articles disponibles
# sur chaun des 3 types avec le nombre traité puis
# print le titre de chaque article à traiter  c-a-d celui qui contient
# le mot clé.
# il faut noter que les articles ne contenant pas le mot clé ne sont pas traités .
# renvoie  un fichier structuré (CSV/JSON) avec :
# titre , date , auteur et la catégorie de l'article.
# le nombre de mots par articles.
# Mots-clés fréquents après nettoyage.
# et un fichier png qui contient un graph sur le nombre d'articles traitant du sujet dans chaque site.
# ce graph nous permet donc de faire une comparaisaon de volume.
#===================================================================================================
#===================================================================================================
# Usage :
# exemple de méthodes d'usage
# perl projet_de_fin_annee.pl --motcle 'eaux' --max 30  --keywords 7
# perl projet_de_fin_annee.pl  -- motcle 'loi' --max 30 --keywords 7 --stopwordss 'plus'
# perl projet_de_fin_annee.pl
#==================================================================================================


# -------------------------------------
# packages utilisées dans le programme.
#--------------------------------------

use strict ; # nous permets de forcer une écriture plus rigoiureuse du code perl.
use warnings ; # pour la gestion des érreurs et le débogage.
use utf8; # pour le formatage en utf8
use open ':std', ':encoding(UTF-8)';  # gérer l'encodage et le formatage dans la sortie standard
use XML::RSS ; # qui va permettre d'analyser flux de données
use LWP::Simple; #  est utiliser ici pour télécharger du contenu depuis le web, en particulier les flux RSS.
use LWP::UserAgent; # utliser pour recupere les flux url au cas où la methode simple ne marche pas.

use Text::CSV; # permet de créer un fichier csv plus robuste
use Getopt::Long; #  Gère les arguments en ligne de commande de façon flexible.
use Text::ParseWords; # va nous Permettre  de découper des chaînes de caractères en mots

use Lingua::StopWords qw(getStopWords);  # Fournit une liste de mots vides ("stopwords") à ignorer lors de
# l’analyse textuelle. exemple le, la, et, de, the, is etc
use Text::Unidecode;  # Pour normaliser les caractères spéciaux
use HTML::TreeBuilder::XPath; # ce module va nous permettre de:
                              # parcer une parge html et récupérer facilement le contenue
use HTML::Strip ;
use Term::ANSIColor; # pour gérer l'affichage dans les sorties standards(en couleur).
use List::Util qw( min );  # pour le calcul des mots
# --------------------------------------------------------------
# initialisation des variables d'entrée   et téléchargement du contenu RSS
#----------------------------------------------------------------

# a) définition  des flux urls  dans une table de hachage:
my %rss_sites = (
                 'Gauche' => 'https://www.humanite.fr/rss/actu.rss',
                 'Droite' => 'https://www.lefigaro.fr/rss/figaro_actualites.xml',
                 'ExtremeDroite' => 'https://www.present.fr/rss'
);

# b) initialisation des variables.

my ($keyword, $stopwords_extra ,$max_articles, $nb_keywords)= ('economie','' ,10, 5);  # nous fixons le nbre d'articles à 20 par défaut.
# et renvoi 5 mots clées par défaut.
# lecture  des options avec le module Getopt::long
GetOptions(
           'motcle=s' => \$keyword, # keyword doit être une chaine de caratères string
           'max=i' => \$max_articles, # le nbre max d'articles doit être un integer
           'keywords=i' => \$nb_keywords, # le nbre max de mots clés à afficher
           'stopwords' => \$stopwords_extra  # '' par défaut
           ) or die " vous avez fait une erreur : option(s) non valide.\n";

die "Usage : perl projet_de_fin_annee.pl --motcle <MOT_CLE> [--max <NOMBRE>] [--keywords <NOMBRE_MOTS_CLES>]\n" unless $keyword; #  permet de faire arrêter le programme si pas url fourni

my %global_word_count;        # Comptage global des mots
my %group_word_count;         # Comptage par groupe politique


# b) téléchargement du contenu RSS  avec une bouche foreach pour les 3 sites;

my %flux_par_site; # cette table nous permets de collecter les flux URL

foreach my $site (keys %rss_sites) {
    my $url = $rss_sites{$site};
    my $rss = XML::RSS->new;# creation d'un nouvel objet RSS
    my $rss_contenu = get($url);
    # la ligne 121  utilise get() de LWP::Simple pour télécharger le contenu XML de l’URL RSS.
    # si la méthode 01 ne marche pas alors :
    # cette methode consiste à se faire passer pour un navigateur en utilisant useraget:
    unless($rss_contenu){
        print "Échec avec LWP::Simple. Tentative avec LWP::UserAgent...\n";
        my $ua = LWP::UserAgent->new;
        $ua->agent("Mozilla/5.0");
        my $response = $ua->get($url);
        die "Erreur avec $site : " . $response->status_line . "\n" unless $response->is_success;
        $rss_contenu = $response->decoded_content;
    }
    
    $rss->parse($rss_contenu); # parsage du contenu de l'url.
    $flux_par_site{$site} = $rss ->{items} # nous stockons la reférence au tableau d'articles
    
}
#----------------------------------------------------------------------
# test du premier bloc de code  pour voir si les articles sont chargés.
# et que les articles sont traités en fonction du mot clé .
#----------------------------------------------------------------------

# creation d'une fonction pour l'extraction du contenu de l'article depuis l'url.
sub get_full_article_text {
    my ($url) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->get($url);
    return "" unless $response->is_success;
    my $html = $response->decoded_content;
    # Parser HTML
    my $tree = HTML::TreeBuilder->new_from_content($html);
    # Récupérer uniquement le texte visible
    my $text = $tree->as_text;
    $tree->delete;
    # Nettoyage : enlever les espaces inutiles
    $text =~ s/\s+/ /g;
    return $text;
}
# fin de la fonction d'extraction
# boucle de test:

foreach my $site (keys %flux_par_site) {
    my @articles = @{ $flux_par_site{$site} };
    my $total_disponibles = scalar @articles;
    my $articles_traite = 0;
    my @articles_matches = ();
    # ce  Limiter au nombre maximum d'articles spécifié
    my $limite; # permet de définir la limite d'articles
    if ($max_articles < $total_disponibles) {
        $limite = $max_articles;
    } else {
        $limite = $total_disponibles;
    }
    #  utilisartion d'une boucle for pour afficher les articles traites et leurs noms.
    for (my $i = 0; $i < $limite; $i++) {
        my $item = $articles[$i];
        
        # Normaliser le titre et mot-clé en minuscules pour une recherche insensible à la casse
        my $desc  = lc($item->{description} // '');
        #my $contenu = lc($item->{content} // '');
        my $url = $item->{link} // "";
        next unless $url;
        my $contenu = get_full_article_text($url);
        next unless length($contenu) > 100;
        my $motcle_lower = lc($keyword);
        # Vérifier si le titre contient le mot-clé
        if (index($contenu, $motcle_lower) != -1 || index($desc, $motcle_lower) != -1) {
            $articles_traite++;
                   push @articles_matches, {
                       numero => $i + 1,
                       titre  => $item->{title} // 'Sans titre'
                   };
        }
    }
    # Affichage enrichi et coloré
    print color('bold blue');
    print "==================================================\n";
    print "🔍 Analyse du site : $site\n";
    print "==================================================\n";
    print color('reset');

    print "📄 Nombre total d'articles disponibles : $total_disponibles\n";
    print "✅ Nombre d'articles traités : $limite\n\n";

    print "📰 Articles contenant le mot-clé \"$keyword\" :$articles_traite\n";
    foreach my $art (@articles_matches) {
        print "  • Article $art->{numero} : $art->{titre}\n";
    }
    print "-" x 50 . "\n";
}
#---------------------------------------------------------
# initialisation du fichier excel  pour stocker les sortie
# et stockage des sorties.
#---------------------------------------------------------
my $csv = Text::CSV->new({ binary => 1, eol => $/ });
open(my $xls , '>:encoding(utf8)' , 'articles_analyse.csv' ) or die " creation d'un fichier excel impossible.\n";
# remplissage du fichier:
print $xls "Titre,Link,Date,Auteur,Categorie,NombreMotes,MotsCles\n";


#  Création d'une Fonction de nettoyage des mots
sub clean_word {
    my $word = lc($_[0]);
    $word =~ s/[^a-zà-ÿ]//g;  # Supprime toute ponctuation
    return $word;
}
# Stopwords (mots à ignorer)
my $stopwords = {
    # Stopwords de base en français
    %{getStopWords('fr')},
    
    # Mots supplémentaires à ignorer
    map { lc($_) => 1 } (
        'les', 'la', 'le', 'des', 'de', 'du', 'au', 'aux', 'que',
     'plus', 'bonjour','figaro','humanité','présent'
    ),
    
    # Mots supplémentaires  à ignorer , donnée en option
    $stopwords_extra ? (map { lc($_) => 1 } split(/[\s,]+/, $stopwords_extra)) : ()
};


#my $motcle_lower = lc($keyword);  # permet de transformer le mot clé  en argument en minuscule.
foreach my $site (keys %flux_par_site) {
    my @articles = @{ $flux_par_site{$site} };
    # Analyse de  chaque article
    my $count = 0; #  compteur pour s'assurer de la limite d'articles analysée.
    foreach my $item (@articles) {
        
        if ($count >= $max_articles){
            last ; # pour permettre de respecter la limite d'articles.
        }
        my $content = '';
        # Filtrage des articles par mot-clé dans le contenue
        my $url = $item->{link} // "";
        next unless $url;
        my $contenu = get_full_article_text($url);
        next unless length($contenu) > 100;
        my $desc_lc  = lc($item->{description} // '');
        my $motcle_lc = lc($keyword);
        next unless index($contenu, $motcle_lc) != -1 || index($desc_lc, $motcle_lc) != -1;  # Recherche le mot clé  dans le contenu
        # extraction des éléments  importants ;
        # pour chaque éléments extraits , si la valeur n'exixte pas, elle
        # est remplacée par un N/A
        
        my $title = $item->{'title'} || 'N/A';
        my $link = $item ->{'link'} || 'N/A';
        my $date  = $item->{'pubDate'} || 'N/A';
        my $author = $item->{'author'} || 'N/A';
        my $category = $item->{'category'} || 'N/A';
        #---------------------------------------------------------------
        # nous allons maintenant lire et nettoyer le contenu de l'article,
        # en utilisant les regex
        # -----------------------------------------------------------------
        
        my $url_article = $item->{'link'} || '';

        # Télécharger le HTML de l'article complet
        my $ua = LWP::UserAgent->new;
        $ua->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0 Safari/537.36");

        my $response = $ua->get($url_article);
        unless ($response->is_success) {
            warn "Impossible de charger l'article complet : $url_article (", $response->status_line, ")\n";
            next;
        }
        my $html_article = $response->decoded_content;
        # Parser le HTML
        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse($html_article);
        $tree->eof;  # nous permet d'indiquer que la page est complètement lue et que l'arbre est prêt
        #------------------------------------------------------------
        # Extraction du contenu selon le site
        # la fonction as_text ici va nous permettre de convertir un
        # noeuds html , en  texte sans balise.
        # et map va nous permettre d'appliquer cela à chaque noeuds @nodes
        #------------------------------------------------------------
        # [Extraction du contenu selon le site...]
    
        if ($site eq 'Gauche') {
            my @nodes = $tree->findnodes('//section[contains(@class,"article__content")]//p');
            $content = join(' ', map { $_->as_text } @nodes);
        } elsif ($site eq 'Droite') {
            my @nodes = $tree->findnodes('//div[contains(@class, "content")]//p');
            $content = join(' ', map { $_->as_text } @nodes);
        } elsif ($site eq 'ExtremeDroite') {
            my @nodes = $tree->findnodes('//div[contains(@class, "content")]//p');
                        $content = join(' ', map { $_->as_text } @nodes);
        } else {
            # Fallback: tous les <p>
            my @nodes = $tree->findnodes('//p');
            $content = join(' ', map { $_->as_text } @nodes);
        }
        
        $tree->delete;
    
        # Compter les mots et extraire les mots-clés
        my @words = grep {
            my $cleaned = clean_word($_);
            length($cleaned) >= 3 && !$stopwords->{$cleaned}
        }
        split(/[^a-zA-ZÀ-ÿ]+/, lc($contenu)); # transformation du contenue en  un tableau de mots.
        my %word_count; # definition d'un dictionnaire pour compter chaque mot
        # boucle foreach pour pour remplir le dictionnaire.
        foreach my $word (@words) {
            $word =~ s/[^a-zA-ZÀ-ÿ]//g;  # Suppression de la ponctuation
            next if length($word) < 3 || $stopwords->{$word};
            $word_count{$word}++;
            # mise en ouevre des statistiques globales.
            $global_word_count{$word} += $word_count{$word}; # statistiques pour tout le monde,
            $group_word_count{$site}{$word} += $word_count{$word}; #stat par site.
        }
        
        # Sélection des mots-clés les plus fréquents
        my @keywords = sort { $word_count{$b} <=> $word_count{$a} } keys %word_count;
        @keywords = @keywords[0..($nb_keywords-1)] if @keywords > $nb_keywords;
        #  affichage des mots-clés avec leur nombre d'apparitions.
        my @keywords_with_counts;  # creation d'une liste pour contenir ses mots.
        foreach my $mot (@keywords) {
            my $mot_formate = "$mot($word_count{$mot})";
            push @keywords_with_counts, $mot_formate; # ajout de la chaine à la liste finale.
        }
        my $keywords_str = join("; ", @keywords_with_counts);
        # Écrire dans le CSV
        $csv->print($xls, [$title, $link, $date, $author, $category, scalar(@words), $keywords_str]);
        $count++;
    }
}
        close($xls);
        print "Analyse terminée. Résultats sauvegardés dans 'articles_analyse.csv'.\n";


#--------------------------------------------------------------------------------
# creation  d'une fonction  pour affichage des statistiqies et affichage de ses
# statistiques.
#----------------------------------------------------------------------------------

sub print_keyword_stats {
    print "\n📊 Statistiques des mots-clés :\n\n";
    
    # Tri global
    my @global_top = sort { $global_word_count{$b} <=> $global_word_count{$a} } keys %global_word_count;
    @global_top = @global_top[0..($nb_keywords-1)] if @global_top > $nb_keywords;
    
    print "🔠 Top $nb_keywords mots-clés globaux :\n";
    foreach my $word (@global_top) {
        printf "  • %s (%d occurrences)\n", $word, $global_word_count{$word};
    }
    
    # Par groupe politique
    foreach my $site (sort keys %group_word_count) {
        my @site_top = sort { $group_word_count{$site}{$b} <=> $group_word_count{$site}{$a} }
                       keys %{$group_word_count{$site}};
        @site_top = @site_top[0..($nb_keywords-1)] if @site_top > $nb_keywords;
        
        print "\n🏛️ Top $nb_keywords mots-clés pour $site :\n";
        foreach my $word (@site_top) {
            printf "  • %s (%d occurrences)\n", $word, $group_word_count{$site}{$word};
        }
    }
}
# appel de la fonctio d'affichage.
print_keyword_stats();

#------------------------------------------------------------------------------
# création d'un second fichier excel pour la sauvegarde des statistiqes.
#-------------------------------------------------------------------------------
open(my $stats_file, '>:encoding(utf8)', 'keywords_stats.csv') or die $!;
my $stats_csv = Text::CSV->new({ binary => 1, eol => $/ });
$stats_csv->print($stats_file, ['Mot', 'Occurrences', 'Sites']);

foreach my $word (sort { $global_word_count{$b} <=> $global_word_count{$a} } keys %global_word_count) {
    my $sites = join ', ', grep { $group_word_count{$_}{$word} } keys %group_word_count;
    $stats_csv->print($stats_file, [$word, $global_word_count{$word}, $sites]);
}
close($stats_file);

#-------------------------------------------------------------------------------
# visualisation statistique
#-------------------------------------------------------------------------------
use Imager; # package pour créer un graphe

# Comptage dynamique des articles analysés par site
my %article_count;  # clé = site, valeur = nombre d'articles traités
#chargement des polices pour écriture sur les graphs
my $font_title = Imager::Font->new(file => '/Library/Fonts/Arial Unicode.ttf', size => 14);
my $font_label = Imager::Font->new(file => '/Library/Fonts/Arial Unicode.ttf', size => 12);
my $font_small = Imager::Font->new(file => '/Library/Fonts/Arial Unicode.ttf', size => 10);

foreach my $site (keys %flux_par_site) {
    my @articles = @{ $flux_par_site{$site} };
    my $count = 0;
    foreach my $item (@articles) {
        last if $count >= $max_articles;
        my $url = $item->{link} // "";
        next unless $url;
        my $contenu = get_full_article_text($url);
        my $desc_lc  = lc($item->{description} // '');
        next unless length($contenu) > 100;
        my $motcle_lc = lc($keyword);
        if (index($contenu, $motcle_lc) != -1 || index($desc_lc, $motcle_lc) != -1) {
            $article_count{$site}++;
            $count++;
        }
    }
}

# Construction des données pour le graphique
my @sites = sort keys %article_count;
my @counts = map { $article_count{$_} } @sites;

# Couleurs politiques (gauche=rouge, droite=bleu, extrême droite=noir)
my %colors = (
    'Gauche'       => Imager::Color->new(200, 50, 50),    # Rouge
    'Droite'       => Imager::Color->new(50, 50, 200),    # Bleu
    'ExtremeDroite' => Imager::Color->new(0, 0, 0)        # Noir
);

my $text_color = Imager::Color->new(0, 0, 0);  # noir
# Dimensions améliorées
my $width = 800;
my $height = 600;
my $bar_width = 80;
my $spacing = 60;
my $margin = 100;
my $baseline = $height - $margin;

# Création de l'image avec fond légèrement gris
my $img = Imager->new(xsize => $width, ysize => $height);
$img->box(filled => 1, color => Imager::Color->new(240, 240, 240));

# Échelle dynamique avec marge
my $max_count = (sort { $b <=> $a } @counts)[0] || 1;
my $scale = ($baseline - 150) / $max_count;

# Dessin des barres avec effets 3D
for my $i (0..$#sites) {
    my $x = $margin + $i * ($bar_width + $spacing);
    my $bar_height = $counts[$i] * $scale;
    
    # Effet 3D
    $img->box(
        xmin => $x + 5,
        ymin => $baseline - $bar_height + 5,
        xmax => $x + $bar_width + 5,
        ymax => $baseline + 5,
        filled => 1,
        color => Imager::Color->new(100, 100, 100),
    );
    
    # Barre colorée
    $img->box(
        xmin => $x,
        ymin => $baseline - $bar_height,
        xmax => $x + $bar_width,
        ymax => $baseline,
        filled => 1,
        color => $colors{$sites[$i]},
    );
    
    # Nom du site en dessous
    $img->string(
        font => $font_label,
        x => $x + 10,
        y => $baseline + 30,
        string => $sites[$i],
        color => $text_color
    );
    
    # Valeur au-dessus de la barre
    $img->string(
        font => $font_small,
        x => $x + 20,
        y => $baseline - $bar_height - 25,
        string => $counts[$i],
        color => $text_color,
        aa => 1
    );
}

# Axes avec flèches
$img->line(x1 => $margin-20, y1 => 50, x2 => $margin-20, y2 => $baseline+10, color => $text_color, endp => 1); # axe Y
$img->line(x1 => $margin-20, y1 => $baseline+10, x2 => $width - 50, y2 => $baseline+10, color => $text_color, endp => 1); # axe X

# Graduations axe Y
for my $i (0..$max_count) {
    my $y = $baseline - ($i * $scale);
    $img->line(x1 => $margin-25, y1 => $y, x2 => $margin-15, y2 => $y, color => $text_color);
    $img->string(
        font => $font_small,
        x => $margin - 40,
        y => $y - 5,
        string => $i,
        color => $text_color
    );
}

# Titre principal et sous-titre
$img->string(
    font => $font_title,
    x => $width/2 - 150,
    y => 30,
    string => "Analyse des tendances politiques",
    color => $text_color
);

$img->string(
    font => $font_label,
    x => $width/2 - 120,
    y => 60,
    string => "Mot-clé: \"$keyword\"",
    color => Imager::Color->new(100, 100, 100)
);

# Légende
my $legend_y = $height - 50;
foreach my $site (sort keys %colors) {
    $img->box(
        xmin => $margin,
        ymin => $legend_y,
        xmax => $margin + 20,
        ymax => $legend_y + 20,
        filled => 1,
        color => $colors{$site}
    );
    $img->string(
        font => Imager::Font->new(file => '/Library/Fonts/Arial Unicode.ttf', size => 14),
        x => $margin + 30,
        y => $legend_y + 15,
        string => $site,
        color => $text_color
    );
    $margin += 150;
}

# Sauvegarde en haute qualité
$img->write(file => 'articles_par_site.png', type => 'png', quality => 90)
    or die "Erreur sauvegarde image: " . $img->errstr;

print "Graphique politique généré : articles_par_site.png\n";
