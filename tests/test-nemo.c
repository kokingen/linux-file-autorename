#include <config.h>
#include <gtk/gtk.h>
#include <locale.h>
#include <glib/gi18n.h>
#include <libnemo-private/nemo-file-operations.h>
#include <libnemo-private/nemo-global-preferences.h>
static void done(GHashTable *h, gboolean ok, gpointer d){ gtk_main_quit(); }
static gboolean watchdog(gpointer d){ g_printerr("TIMEOUT (dialog?)\n"); exit(3); }
int main(int argc, char**argv){
  setlocale(LC_ALL,""); bindtextdomain("nemo","/usr/share/locale"); bind_textdomain_codeset("nemo","UTF-8"); textdomain("nemo");
  gtk_init(&argc,&argv);
  nemo_global_preferences_init();
  if(argc<4){g_printerr("usage: copy|move DEST SRC...\n");return 2;}
  GdkDragAction a = strcmp(argv[1],"move")==0?GDK_ACTION_MOVE:GDK_ACTION_COPY;
  GFile *d=g_file_new_for_commandline_arg(argv[2]); char *duri=g_file_get_uri(d);
  GList *l=NULL; for(int i=3;i<argc;i++){GFile*f=g_file_new_for_commandline_arg(argv[i]); l=g_list_append(l,g_file_get_uri(f));}
  g_timeout_add_seconds(20,watchdog,NULL);
  nemo_file_operations_copy_move(l,NULL,duri,a,NULL,done,NULL);
  gtk_main(); return 0;
}
