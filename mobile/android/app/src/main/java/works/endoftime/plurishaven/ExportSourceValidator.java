package works.endoftime.plurishaven;

import java.io.File;
import java.io.IOException;

final class ExportSourceValidator {
    private static final String EXPORT_DIRECTORY_PREFIX = "pluris-haven-export-";

    private ExportSourceValidator() {}

    static boolean isOwned(File source, File cacheDirectory) {
        try {
            File canonicalSource = source.getCanonicalFile();
            File stagingDirectory = canonicalSource.getParentFile();
            if (!canonicalSource.isFile()
                    || stagingDirectory == null
                    || !stagingDirectory.getName().startsWith(EXPORT_DIRECTORY_PREFIX)) {
                return false;
            }

            File canonicalCacheDirectory = cacheDirectory.getCanonicalFile();
            for (File parent = stagingDirectory.getParentFile();
                 parent != null;
                 parent = parent.getParentFile()) {
                if (parent.equals(canonicalCacheDirectory)) return true;
            }
            return false;
        } catch (IOException error) {
            return false;
        }
    }
}
